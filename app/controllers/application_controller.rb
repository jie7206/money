require 'socket'

class ApplicationController < ActionController::Base

  include ApplicationHelper

  before_action :check_login, except: [ :login, :update_all_data ]
  before_action :summary, :memory_back, only: [ :index ]

  # 初始化设置
  def initialize
    super
    $system_params_path = "#{Rails.root}/config/system_params.txt"
    load_global_variables
    Currency.add_or_renew_ex_rates # 方便汇率转换直接调用，无需再次查询数据库
  end

  # 取得主机IP
  def get_host_ip
    ip = get_local_ip.to_s
    if ip.index("192.")
      return ip
    else
      return $host_public_ip
    end
  end

  # 取得本机IP
  def get_local_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true
    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1  #google的ip
      s.addr.last
    end
    ensure
      Socket.do_not_reverse_lookup = orig
  end

  # 读入网站所有的全局参数设定
  def load_global_variables
    eval(File.open($system_params_path,'r').read)
    eval(File.open("#{Rails.root}/config/global_variables.txt",'r').read)
  end

  # 所有页面需要输入PIN码登入之后才能使用
  def check_login
    redirect_to login_path if !login?
  end

  # 如果不是管理员则回到登入页重新登入
  def check_admin
    redirect_to login_path if !admin?
  end

  # 火币费率
  def fee_rate
    1-$fees_rate
  end

  # 更新主要资料
  def update_all_data
    put_notice `python py/update_all.py`
    update_legal_exchange_rates
    update_portfolios_and_records
    go_back
  end

  # 更新法币及数字货币汇率
  def update_exchange_rates
    update_legal_exchange_rates
    update_digital_exchange_rates
  end



  # 显示当前时间
  def now
    Time.now.strftime("%H:%M")
  end

  # 从火币网取得某一数字货币的最新报价
  def get_huobi_price( symbol )
    begin
      root = JSON.parse(`python py/huobi_price.py symbol=#{symbol} period=1min size=1`)
      if root["data"] and root["data"][0]
        return format("%.2f",root["data"][0]["close"]).to_f
      else
        return 0
      end
    rescue
      return 0
    end
  end

  # 更新所有数字货币的汇率值
  def update_digital_exchange_rates
    # 必须先更新USDT的汇率，其他的报价换算成美元才能准确
    usdt = Currency.usdt
    cny_exchange_rate = get_exchange_rate(:usd,'CNY')
    usdt_price = $usdt_to_cny/cny_exchange_rate
    update_exchange_rate(usdt.code,(1/usdt_price).floor(8))
    count = 1
    if usdt_price = get_huobi_price(usdt.symbol) and usdt_price > 0
      count += 1
      Currency.digitals.each do |c|
        next if c.code == 'USDT'
        if price = get_huobi_price(c.symbol) and price > 0
          update_exchange_rate(c.code,(1/(price*usdt_price)).floor(8))
          count += 1
        end
      end
    end
    put_notice "#{count} #{t(:n_digital_exchange_rates_updated_ok)}" if count > 0
    return count
  end

  # 更新所有法币的汇率值
  def update_legal_exchange_rates
    count = 0
    Currency.legals.each do |c|
      code = c.code
      next if code == 'USD'
      if value = get_exchange_rate(:usd,code) and value > 0
        update_exchange_rate( code, value )
        count += 1
      end
    end
    put_notice "#{count} #{t(:n_legal_exchange_rates_updated_ok)}" if count > 0
    return count
  end

  # 取得URI连线的回传值
  def get_uri_response( url )
    return Net::HTTP.get_response(URI.parse(url)).body
  end

  # 取得SSL连线的回传值
  def get_ssl_response( url, authorization = nil )
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 90
    if url.split(':').first == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    if authorization
      header = {'Authorization':authorization}
      response = http.get(url, header)
    else
      response = http.get(url)
    end
    return response.body
  end

  # 取得最新法币汇率的报价
  def get_exchange_rate( from_code, to_code )
    url = "https://ali-waihui.showapi.com/waihui-transform?fromCode=#{from_code.to_s.upcase}&toCode=#{to_code.to_s.upcase}&money=1"
    resp = get_ssl_response(url,"APPCODE de9f4a29c5eb4c73b0be619872e18857")
    if rate = Regexp.new(/(\d)+\.(\d)+/).match(resp)
      return rate[0].to_f
    else
      return 0
    end
  end

  # 更新单一货币的汇率值
  def update_exchange_rate( code, value )
    if currency = Currency.find_by_code(code)
      currency.update_attribute(:exchange_rate,value)
      return value
    end
  end

  # 记录返回的网址
  def memory_back( given_path = request.fullpath )
    session[:path] = params[:path] ? params[:path] : given_path
  end

  # 返回记录的网址
  def go_back
    if params[:path]
      redirect_to params[:path]
    elsif session[:path]
      redirect_to session[:path]
      session.delete(:path)
    else
      redirect_to root_path
    end
  end

  # 在通知讯息后面加上物件的ID
  def add_id( object )
    " id: #{object.id}"
  end

  # 在通知讯息后面加上物件的ID
  def add_amount( object )
    begin
      " amount: #{object.amount}"
    rescue
      ""
    end
  end

  # 更新所有的资产组合栏位数据
  def update_all_portfolio_attributes
    Portfolio.all.each do |p|
      properties = get_properties_from_tags(p.include_tags,p.exclude_tags,p.mode)
      update_portfolio_attributes(p.id, properties)
    end
    put_notice t(:portfolios_updated_ok)
  end

  # 更新所有模型的数值记录
  def update_all_record_values
    properties_net_value_guest = Property.net_value :twd, admin_hash(false)
    properties_net_value_admin = Property.net_value :twd, admin_hash(true)
    $record_classes.each do |class_name|
      case class_name
        when 'NetValue'
          Property.record class_name, 1, properties_net_value_guest.to_i
        when 'NetValueAdmin'
          Property.record class_name, 1, properties_net_value_admin.to_i
        else
          eval(class_name).update_all_records
      end
    end
    put_notice t(:all_records_updated_ok)
  end

  # 更新资产组合栏位数据
  def update_portfolio_attributes( id, properties )
    twd_amount, cny_amount, proportion = get_portfolio_attributes(properties)
    Portfolio.find(id).update_attributes(
      twd_amount: twd_amount.to_i,
      cny_amount: cny_amount.to_i,
      proportion: proportion)
  end

  # 取得资产组合栏位数据
  def get_portfolio_attributes( properties )
    twd_amount = cny_amount = proportion = 0.0
    properties.each do |p|
      twd_amount += p.amount_to(:twd).to_i
      cny_amount += p.amount_to(:cny).to_i
      proportion += p.proportion(admin?).to_f
    end
    return [twd_amount, cny_amount, proportion]
  end

  # 获取资产的净值等统计数据
  def summary( admin = admin? )
    @show_summary = params[:tags] ? false : true
    @properties_net_value_twd = Property.net_value :twd, admin_hash(admin)
    @properties_net_value_cny = Property.net_value :cny, admin_hash(admin)
    @properties_lixi_twd = Property.lixi :twd, admin_hash(admin)
    @properties_value_twd = Property.value :twd, admin_hash(admin,only_positive: true)
    @properties_loan_twd = Property.value :twd, admin_hash(admin,only_negative: true)
    @properties_loan_cny = Property.value :cny, admin_hash(admin,only_negative: true)
    @properties_net_growth_ave_month = (Property.net_growth_ave_month :twd, admin_hash(admin)).to_i
    @properties_net_growth_ave_month_cny = (Property.net_growth_ave_month :cny, admin_hash(admin)).to_i
    @properties_growth_pass_days = Property.pass_days
    # 访问资产负债表时能自动写入资产净值到数值记录表
    Property.record get_class_name_by_login, 1, @properties_net_value_twd.to_i
  end

  # 若以管理员登入则写入到NetValueAdmin否则NetValue
  def get_class_name_by_login
    admin? ? 'NetValueAdmin' : 'NetValue'
  end

  # 生成FusionCharts的XML资料的辅助方法
  def find_rec_date_value( records, date, value_field_name, rec_date_field_name )
    records.each do |r|
      return r.send(value_field_name) if r.send(rec_date_field_name).to_date.to_s(:db) == date.to_s(:db)
    end
    return nil
  end

  # 设定线图最大值和最小值
  def set_fusion_chart_max_and_min_value
    factor = 1.5 # 调整上下值，让图好看点，值越小离边界越近，不可小于1
    @min_value = @data_arr.min
    @max_value = @data_arr.max
    @newest_value = @data_arr.last
    @before_newest_value = @data_arr[-2]
    pos = @min_value < 1 ? 4 : 2 # 如果数值小于1，则显示小数点到4位，否则2位
    if @min_value == @max_value
      @top_value = to_n(@min_value*(1+(factor-1)),pos)
      @bottom_value = to_n(@min_value*(1-(factor-1)),pos)
    else
      mid_value = (@max_value + @min_value)/2
      center_diff = (@max_value - mid_value).abs #与中轴距离=最大值-中间值
      @top_value = to_n(mid_value + center_diff*factor,pos) #新最大值=中间值+与中轴距离*调整因子
      @bottom_value = to_n(mid_value - center_diff*factor,pos) #新最小值=中间值-与中轴距离*调整因子
    end
  end

  # 生成FusionCharts的XML资料
  def build_fusion_chart_data( class_name, oid, chart_data_size = $chart_data_size )
    @name = class_name.index('Net') ? '资产总净值' : eval(class_name).find(oid).name
    records = Record.where(["class_name = ? and oid = ? and updated_at >= ?",class_name,oid,Date.today-chart_data_size.days]).order('updated_at')
    # 依照资料笔数的多寡来决定如何取图表中第一个值
    case records.size
      when 0
        last_record = Record.where(["class_name = ? and oid = ?",class_name,oid]).last
        last_value = last_record ? last_record.value : 0
      else
        last_value = records.first.value
    end
    today = Date.today
    start_date = today - chart_data_size.days
    @chart_data = ''
    @data_arr = [] # 为了找出最大值和最小值
    start_date.upto(today) do |date|
      this_value = find_rec_date_value(records,date,'value','updated_at')
      if this_value
        value = this_value
        last_value = this_value
      else
        this_value = last_value
      end
      @data_arr << this_value
      @chart_data += "<set label='#{date.strftime("%Y-%m-%d")}' value='#{this_value}' />"
    end
    set_fusion_chart_max_and_min_value
    t2c = Property.new.twd_to_cny
    if @newest_value < 100
      @newest_value_diff = @newest_value - @before_newest_value
      @newest_value_rate = @newest_value_diff/@before_newest_value*100
    else
      @newest_value_diff = (@newest_value - @before_newest_value).to_i
      @newest_value_rate = @newest_value_diff/@before_newest_value*100
      @before_newest_value = @before_newest_value.to_i
      @newest_value = @newest_value.to_i
      @min_value = @min_value.to_i
      @max_value = @max_value.to_i
    end
    if @newest_value_diff > 0
      show_newest_value_diff = "+#{@newest_value_diff} | +#{to_n(@newest_value_rate)}%"
    else
      show_newest_value_diff = "#{@newest_value_diff} | #{to_n(@newest_value_rate)}%"
    end
    @caption = "#{@name} #{chart_data_size}天走势图 最新 #{@before_newest_value} ( #{show_newest_value_diff} ) ➠  #{@newest_value} | #{(@newest_value*t2c).to_i} ( #{@min_value} | #{(@min_value*t2c).to_i} ➠ #{@max_value} | #{(@max_value*t2c).to_i} )"
  end

  # 显示走势图
  def chart
    build_fusion_chart_data(self.class.name.sub('Controller','').singularize,params[:id])
    render template: 'shared/chart'
  end

  # 更新比特币报价
  def update_btc_price( btc_price = 0 )
    btc_price = get_huobi_price('btcusdt') if btc_price == 0
    if btc_price > 0
      Currency.find_by_code('BTC').update_price(btc_price)
      return true
    else
      return false
    end
  end

  # 更新燕大星苑房屋单价
  def update_yanda_house_price
    # 安居客
    # url_1 = "https://qinhuangdao.anjuke.com/community/trends/387687"
    # pattern_1 = /\"comm_midprice\":\"(\d+)\"/
    # 房天下
    # url_2 = "https://yandaxingyuanhongshuwan.fang.com/"
    # pattern_2 = /var price = \"(\d+)\"/
    # 赶集网
    url = "http://qinhuangdao.ganji.com/xiaoqu/yandaxingyuanhongshuwan92JO/"
    pattern = /class=\"price\">(\d+)/
    code = get_ssl_response(url)
    if code and matches = Regexp.new(pattern).match(code).to_a and price = matches[1].to_i
      if price > 0
        Item.house.update_attribute(:price,price)
        put_notice t(:yanda_house_price_updated_ok)
      elsif code.empty?
        put_notice t(:source_empty)
      end
    end
  end

  # 连线读取火币账号的资产余额
  def get_huobi_assets( huobi_obj )
    root = huobi_obj.balances
    if root["status"] == "ok"
      result = []
      root["data"]["list"].each do |item|
        data = {}
        if item["balance"].to_f > 0.000000001
          data[:currency] = item["currency"]
          data[:type] = item["type"]
          data[:balance] = to_n(item["balance"].to_f,8)
          result << data
        end
      end
      return result
    else
      return nil
    end
  end

  # 合并trade与frozen两种type
  def sum_huobi_assets( arr )
    if arr and arr.size > 0
      result = []
      arr.each do |asset|
        data = {}; trade = frozen = 0
        trade = (arr.select {|a| a[:currency]==asset[:currency] and a[:type]=='trade'}).first[:balance].to_f
        if f = (arr.select {|a| a[:currency]==asset[:currency] \
            and a[:type]=='frozen'}) and f.size > 0
          frozen = f.first[:balance].to_f
        end
        data[:code] = asset[:currency].upcase
        data[:amount] = to_n(trade+frozen,8)
        result << data
      end
      return result
    end
  end

  # 更新所有的资产组合栏位数据和所有模型的数值记录
  def update_portfolios_and_records
    update_all_portfolio_attributes # 更新所有的资产组合栏位数据
    update_all_record_values # 更新所有模型的数值记录
  end

  # 获取手机号码
  def phone_number( pno )
    case pno.to_s
      when '135' then return '13581706025'
      when '170' then return '17099311026'
    end
  end

  # 获取货币识别ID，若无则新增
  def get_or_create_currency( code )
    if currency = Currency.find_by_code(code)
      return currency.id
    else
      new_currency = Currency.create(
        name: code.capitalize,
        code: code,
        symbol: "#{code.downcase}usdt",
        exchange_rate: 1.0
      )
      return new_currency.id
    end
  end

  # 更新交易下单的已实现损益
  def update_all_real_profits
    DealRecord.order('id desc').limit($real_records_limit).each do |dr|
      if dr.order_id and !dr.order_id.empty? and !dr.real_profit
        root = eval("@huobi_api_#{dr.account}").order_status(dr.order_id)
        if root["status"] == "ok"
          price = root["data"]["price"].to_f
          amount = root["data"]["amount"].to_f
          field_amount = root["data"]["field-amount"].to_f
          field_cash_amount = root["data"]["field-cash-amount"].to_f
          field_fees = root["data"]["field-fees"].to_f
          if amount == field_amount
            real_profit = (field_cash_amount-field_fees-(dr.price*dr.amount))*dr.usdt_to_cny
            dr.update_attribute(:real_profit,to_n(real_profit,4).to_f)
          end
        end
      end
    end
  end

  # 返回K线数据（蜡烛图）
  # period : 1min, 5min, 15min, 30min, 60min, 4hour, 1day, 1mon, 1week, 1year
  def get_kline( default_period = $default_chart_period, default_size = $chart_data_size, default_symbol = "btcusdt" )
    symbol = params[:symbol] ? params[:symbol] : default_symbol
    period = params[:period] ? params[:period] : default_period
    size = params[:size] ? params[:size] : default_size
    @symbol_title = symbol_title(symbol)
    @period_title = period_title(period)
    begin
      root = JSON.parse(`python py/huobi_price.py symbol=#{symbol} period=#{period}  size=#{size}`)
      return root["data"].reverse! if root["data"] and root["data"][0]
    rescue
      return []
    end
  end

  # 计算买卖双方成交量比值
  def cal_buy_sell_rate( data = get_kline )
    if data.size > 0
      buy_amount = sell_amount = 0
      data.each do |item|
        buy_amount += item["amount"].to_f if item["close"].to_f >= item["open"].to_f
        sell_amount += item["amount"].to_f if item["close"].to_f < item["open"].to_f
      end
      price_now = data[-1]["close"].to_f
      return price_now, buy_amount.to_i, sell_amount.to_i, format("%.2f",buy_amount/sell_amount)
    else
      return 0, 0, 0, 0
    end
  end

  # 取得BTC现价
  def get_price_now
    get_btc_price
  end

  # 美元换台币
  def usd2twd
    return $twd_exchange_rate
  end

  # 美元换人民币
  def usd2cny
    return $cny_exchange_rate
  end

  # 人民币换台币
  def cny2twd
    return $twd_exchange_rate/$cny_exchange_rate
  end

  # 获取定投参数的值
  def get_invest_params( index )
    File.read($auto_invest_params_path).split(' ')[index]
  end

  # 储存定投参数的值
  def set_invest_params( index, value )
    begin
      params_values = File.read($auto_invest_params_path).split(' ')
      params_values[index.to_i] = value.to_s
      write_invest_params params_values.join(' ')
      return true
    rescue
      return false
    end
  end

  # 写入定投参数
  def write_invest_params( text )
    begin
      File.open($auto_invest_params_path, 'w+') do |f|
        f.write(text)
      end
      return true
    rescue
      return false
    end
  end

  # 获取单次最多卖出笔数
  def get_max_sell_count
    get_invest_params(13).to_i
  end

  # 定投秒数尾数是0则回传1反之亦然
  def swap_sec
    sec = get_invest_params(0)
    return sec[-1] == '0' ? sec[0..-2]+'9' : sec[0..-2]+'0'
  end

  # 读取火币APP的账号ID
  def get_huobi_acc_id
    get_invest_params(24)
  end

  # 设定是否自动刷新页面
  def setup_auto_refresh_sec
    @auto_refresh_sec = $auto_refresh_sec_for_deal_records if $auto_refresh_sec_for_deal_records > 0
  end

  # 更新火币2个账号的资产余额
  def exe_update_huobi_assets
    ori_acc_id = get_huobi_acc_id
    ['135','170'].each do |acc_id|
      set_invest_params( 24, acc_id )
      sleep 1
      # put_notice acc_id + "：" + `python py/update_assets.py`
      `python py/update_assets.py`
    end
    set_invest_params( 24, ori_acc_id )
  end

  # 更新交易列表上的总成本与比特币总数以供跨网站计算均价使用
  def update_deal_cost_amount
    set_invest_params(25,DealRecord.total_cost.floor(4))
    set_invest_params(26,DealRecord.total_amount.floor(8))
  end

  # 记录交易列表上的已实现损益以供跨网站计算总的已实现损益使用
  def update_total_real_profit
    set_invest_params(28,\
      DealRecord.total_real_profit.to_i.to_s+':'+\
      DealRecord.total_unsell_profit.to_i.to_s+':'+\
      DealRecord.real_profit_ave_sec.floor(4).to_s+':'+\
      DealRecord.real_profit_of_24h($send_to_trezor_time).to_i.to_s+':'+\
      to_n(DealRecord.trezor_total_cost,4)+':'+\
      to_n(DealRecord.trezor_total_amount,8))
  end

  # 更新火币资产
  def update_huobi_assets_core
    update_btc_price
    exe_update_huobi_assets
    update_deal_cost_amount
    update_total_real_profit
  end

  # 计算两时间间隔天数
  def day_diff( from_time, to_time = 0, include_seconds = false )
      from_time = from_time.to_time if from_time.respond_to?(:to_time)
      to_time = to_time.to_time if to_time.respond_to?(:to_time)
      begin
        return (((to_time - from_time).abs)/86400).round
      rescue
        return 0
      end
  end

  # 建立回到目录页的方法
  $models.each do |n|
    define_method "go_#{n.pluralize}" do
      eval("redirect_to controller: :#{n.pluralize}, action: :index")
    end
  end

  # 建立各种通知消息的方法
  $flashs.each do |type|
    define_method "put_#{type}" do |msg|
      eval %Q[
        flash[:#{type}] ? flash[:#{type}].gsub!(\"(\#{now})\",'') : flash[:#{type}] = ''
        flash[:#{type}] += \"\#{msg} (\#{now})\"
        flash[:#{type}].gsub!(\"<_io.TextIOWrapper name='<stdout>' mode='w' encoding='UTF-8'>\",'')
      ]
    end
  end

  # 建立从列表中快速更新某个值的方法
  $quick_update_attrs.each do |setting|
    m = setting.split(':')[0]; attrs = setting.split(':')[1].split(',')
    attrs.each do |a|
      define_method "update_#{m}_#{a}" do
        eval %Q[
          if new_#{a} = params[\"new_#{a}_\#{params[:id]}\"]
            new_#{a}.gsub!(',','')
            @#{m}.update_attribute(:#{a}, new_#{a})
            put_notice t(:#{m}_updated_ok) + add_id(@#{m}) + add_amount(@#{m})
          end
          session[:path] ? go_back : go_#{m.pluralize}
        ]
      end
    end
  end

end
