require 'json'

class MainController < ApplicationController

  skip_before_action :verify_authenticity_token, :only => [:order_calculate, :place_order]

  # 显示走势图
  def chart
    build_fusion_chart_data(get_class_name_by_login,1)
    render template: 'shared/chart'
  end

  # 显示登入表单及接受登入表单
  def login
    if correct_pincode? and admin?
      redirect_to root_path
    elsif correct_pincode?
      redirect_to root_path
    end
  end

  # 执行登出
  def logout
    session.delete(:login)
    session.delete(:admin)
    session.delete(:path)
    redirect_to login_path
  end

  # 验证输入的PIN码是否正确
  def correct_pincode?
    if input_pincode? and params[:pincode].split(':')[0] == $pincode
      session[:login] = true
      check_admin?
      return true
    elsif input_pincode?
      flash.now[:warning] = $login_error_message
      return false
    end
  end

  # 验证是否以管理员身份登入
  def check_admin?
    if input_pincode? and params[:pincode].split(':')[1] == $admincode
      session[:admin] = true
    else
      session[:admin] = false
    end
  end

  # 是否有从表单输入PIN值
  def input_pincode?
    params[:pincode] and !params[:pincode].empty?
  end

  # 更新火币所有账号的资料
  def update_huobi_data
    if update_all_huobi_assets > 0 and update_huobi_deal_records
      update_portfolios_and_records
    end
    go_back
  end

  # 更新火币资产
  def update_huobi_assets
    update_huobi_assets_core
    go_back
  end

  # 更新火币交易记录
  def update_huobi_records
    update_huobi_deal_records
    update_all_real_profits
    go_back
  end

  # 火币下单确认页
  def place_order_form
    if params[:id]
      @deal_record_id = params[:id]
      if deal_record = DealRecord.find(@deal_record_id)
        @amount = deal_record.real_amount.floor(6)
        if params[:type] == 'earn'
          @price = deal_record.earn_limit_price
        elsif params[:type] == 'loss'
          @price = deal_record.loss_limit_price
        else
          @price = btc_price
        end
      end
      @deal_type = 'sell-limit'
    elsif params[:amount]
      @amount = params[:amount].to_f
      @price = btc_price
      @deal_type = 'sell-limit'
    elsif params[:sell_all]
      @amount = to_n(DealRecord.btc_amount, 6)
      @price = btc_price
      @deal_type = 'sell-limit'
    else
      @price = btc_price
      @deal_type = 'buy-limit'
    end
    default_order_info
  end

  # 默认的下单讯息
  def default_order_info
    @btc_amount = to_n(DealRecord.btc_amount, 6) # 显示BTC数量
    @btc_level = to_n(DealRecord.btc_level) # 显示目前仓位
    @usdt_amount = to_n(DealRecord.usdt_amount) # 显示剩余资金
    @btc_available, @usdt_available = `python py/usdt_trade.py`.split(',').map {|n| to_n(n,6).to_f}
    @ave_cost = to_n(Property.btc_ave_cost)
    @profit_cny = to_n(DealRecord.profit_cny(@price.to_f))
    remain_usdt2cny
  end

  # USDT转CNY
  def remain_usdt2cny
    # 显示剩余资金(¥)
    if $usdt_to_cny
      @cny_amount = (@usdt_amount.to_f*$usdt_to_cny).to_i
    else
      @cny_amount = (@usdt_amount.to_f*usd2cny).to_i
    end
  end

  # 取得下单参数
  def get_order_params
    @deal_type = params[:deal_type]
    @deal_record_id = params[:deal_record_id]
    @price = params[:price].to_f
    @amount = params[:amount].to_f
  end

  # 执行下单试算
  def order_calculate
    default_order_info
    get_order_params
    @usdt_available ||= 0
    if @deal_type and @deal_type.include? 'buy' and @price * @amount > 1
      @usdt_available = to_n(@usdt_available - @price * @amount)
      @btc_level = to_n((DealRecord.twd_of_btc + @price * @amount * fee_rate * usd2twd) / DealRecord.twd_of_acc_id * 100)
      @btc_amount = to_n(DealRecord.btc_amount + @amount * fee_rate, 6)
      @ave_cost = to_n((Property.btc_total_cost_usdt+@price*@amount)/(Property.total_btc_amount+@btc_amount.to_f))
    elsif @deal_type and @deal_type.include? 'sell' and @price * @amount > 1
      @amount = @btc_available if @btc_available - @amount < 0
      @usdt_amount = to_n(@usdt_amount.to_f + @price * @amount * fee_rate)
      @btc_level = to_n((DealRecord.twd_of_btc - @price * @amount * usd2twd) / DealRecord.twd_of_acc_id * 100)
      @btc_available = to_n(@btc_available - @amount, 6)
      @profit_cny = to_n(DealRecord.profit_cny(@price.to_f))
    else
      flash.now[:warning] = t(:order_error)
      @amount = ''
      default_order_info
    end
    remain_usdt2cny
    @btc_level = 0 if @btc_level.to_f < 0
    render :place_order_form
  end

  # 执行火币下单
  def place_order
    get_order_params
    begin
      root = JSON.parse(`python py/place_order.py symbol=btcusdt deal_type=#{@deal_type}  price=#{@price} amount=#{@amount}`)
    rescue
      root = nil
    end
    if root and root["status"] == "ok"
      order_id = root["data"]
      if @deal_record_id.to_i > 0 and dr = DealRecord.find(@deal_record_id)
        dr.update_attribute(:order_id,order_id)
      end
      put_notice "#{t(:place_order_ok)} #{t(:deal_record_order_id)}: #{order_id}"
      put_notice `python py/open_orders.py`
      go_open_orders
    else
      put_notice t(:place_order_failure)
      go_deal_records
    end
  end

  # 查看火币下单情况
  def look_order
    root = JSON.parse(`python py/look_order.py order_id=#{params[:id]}`)
    render :json => root
  end

  # 取消火币下单
  def del_huobi_orders
    order_id = params[:order_id]
    root = JSON.parse(`python py/cancel_order.py order_id=#{order_id}`)
    if root["status"] == "ok"
      DealRecord.find_by_order_id(order_id).clear_order
      put_notice t(:cancel_order_ok)
    end
    go_deal_records
  end

  # API测试
  def get_huobi_assets_test
    root = `python py/HuobiServices.py`
    respond_to do |format|
      format.json  { render :json => root }
    end
  end

  # 为图表预备需要的资料
  def prepare_chart_data
    if @raw_data = get_kline and @raw_data.size > 0
      @page_title = "#{@symbol_title} #{@period_title}K线走势图"
      @timestamp = get_timestamp
      # 建构K线图副标题
      ma_str = ""
      [5,10,20,30,60].each do |n|
        ma_str += " MA#{n}: #{ma(n)}(#{pom(n)}%)"
      end
      price_now, buy_amount, sell_amount, buy_sell_rate = cal_buy_sell_rate(@raw_data)
      @subcaption = "收: #{@raw_data[-1]["close"]} 高: #{@raw_data[-1]["high"]} 低: #{@raw_data[-1]["low"]} 中: #{mid(@raw_data[-1]["high"],@raw_data[-1]["low"])}#{ma_str} 买: #{buy_amount} 卖: #{sell_amount} 比: #{buy_sell_rate}"
      return true
    else
      return false
    end
  end

  # 显示K线图
  def kline_chart
    if prepare_chart_data
      setup_auto_refresh_sec
      render layout: nil
    else
      render plain: 'Connect Error!'
    end
  end

  # 显示折线图
  def line_chart
    if prepare_chart_data
      @chart_data = ''
      @data_arr = []
      @raw_data.each do |data|
        this_value = data["close"]
        @data_arr << this_value
        @chart_data += "<set label='#{Time.at(data["id"]).strftime("%y%m%d %H:%M")}' value='#{this_value}' />"
      end
      set_fusion_chart_max_and_min_value
      @caption = "#{@page_title} 最新 #{@newest_value} ( #{@min_value} ➠ #{@max_value} )"
      @show_period_link = true
      @no_header = true
      render template: 'shared/chart'
    else
      render plain: 'Connect Error!'
    end
  end

  # 计算中间价
  def mid(high, low)
    return format("%.2f",(high.to_f+low.to_f)/2).to_f
  end

  # 计算MA值
  def ma(size, data=@raw_data, type="middle", dot=0) # 要算几个值的平均, 原始数据阵列, 价格类型,
    if @raw_data.size and @raw_data.size > 0 # fix "divided by 0" bug
      #小数点几位
      size = @raw_data.size if size > @raw_data.size
      temp = 0
      data[size*-1..-1].each do |item|
        if type == "middle" # 最高价与最低价的平均
          middle_price = mid(item["high"], item["low"])
          temp += middle_price
        else
          temp += item[type].to_f
        end
      end
      return format("%.#{dot}f", temp/size)
    end
  end

  # 计算现价与MA的溢价比例
  def pom(size, price=@raw_data[-1]["close"].to_f, dot=2) # MA几, 最新收盘价, 小数点几位
    ma = ma(size).to_f
    return add_plus(format("%.#{dot}f", ((price-ma)/ma)*100))
  end

  # 183将Python脚本在控制台输出的讯息写到文档然后可以点击网页查看
  def read_auto_invest_log
    @content = File.read($auto_invest_log_path)
    if $keep_invest_log_num > 0
      line = $log_split_line
      if @content.include? line
        @content = @content.split(line).reverse.join(line)
      end
    end
  end

  # 设置定投参数表单
  def set_auto_invest_form
    @invest_params_value = File.read($auto_invest_params_path)
    @price_now = get_price_now
  end

  # 设置定投参数
  def set_auto_invest_params
    if text = params[:auto_invest_params] and text.split(' ').size == $exe_auto_invest_params_size
      write_invest_params text
      put_notice show_set_auto_invest_params_ok
    else
      put_notice t(:set_auto_invest_params_error)+"(#{$exe_auto_invest_params_size})"
    end
    redirect_to set_auto_invest_form_path
  end

  # 快速设置定投参数
  def setup_invest_param
    if index = params[:i] and index.to_i < $exe_auto_invest_params_size and value = params[:v]
      set_invest_params(index,value)
      set_invest_params(0,swap_sec)
      # 如果每隔几点购买额度翻倍 > 0 则必须设定多少价位以下执行买入
      # 取消点击每隔几点购买额度翻倍时自动更新额度翻倍的最大购买价除非它等于零
      if index.to_i == 33 and value.to_i > 0 and get_invest_params(34).to_i == 0
        set_invest_params(34,get_int_price(get_price_now))
      end
      # 定价的策略和买最低价的策略无法并存
      if index.to_i == 1 and get_invest_params(1).to_i > 0
        set_invest_params(17,0)
      elsif index.to_i == 17 and get_invest_params(17).to_i > 0
        set_invest_params(1,0)
      end
      # 定价卖出的策略和卖最高价的策略无法并存
      if index.to_i == 18 and get_invest_params(18).to_i > 0
        set_invest_params(27,0)
      elsif index.to_i == 27 and get_invest_params(27).to_i > 0
        set_invest_params(18,0)
      end
      put_notice show_set_auto_invest_params_ok index, value
    else
      put_notice t(:set_auto_invest_params_error)
    end
    redirect_to set_auto_invest_form_path
  end

  # 定投参数设置成功讯息
  def show_set_auto_invest_params_ok( index = nil, value = nil )
    info = (index and value) ? "(#{index} = #{value}) 现价每笔投资¥#{single_invest_cost.to_i} \
      最低价每笔投资¥#{max_invest_cny.to_i}" : ""
    t(:set_auto_invest_params_ok) + info
  end

  # 设置系统参数表单
  def system_params_form
    @system_params_content = File.read($system_params_path)
  end

  # 更新系统参数
  def update_system_params
    if text = params[:system_params_content] and pass_system_params_check(text)
      File.open($system_params_path, 'w+') do |f|
        f.write(text)
      end
      put_notice t(:update_system_params_ok)
    else
      put_notice t(:update_system_params_error)
    end
    redirect_to action: :system_params_form
  end

  # 建立漲跌試算表列出可买币数、累计币数、等值台币及资产净值
  def rise_fall_list
    @price_now = get_price_now
    @invest_fund_usdt = (Property.investable_fund_records_cny/$usdt_to_cny).floor(4)
    @acc_btc_amount = Property.acc_btc_amount # 该账号BTC数量
    @total_btc_amount = Property.total_btc_amount # 比特币的总数
    @total_loan_lixi = Property.total_loan_lixi # 贷款(含利息)的总额
  end

  private

    # 系统参数的更新必须确保每一行以钱号开头以免系统无法运作
    def pass_system_params_check(text)
      regx = /^(\$)(\w)+(\s)+(=){1}(\s)+(.)+/
      text.split("\n").each do |line|
        return false if (line =~ regx) != 0
      end
      return true
    end

    # 计算以现价购买的每笔投资金额
    def single_invest_cost
      price_now = get_price_now             # 取得BTC现价
      bottom = get_invest_params(2).to_f    # 跌破多少价位停止买入
      ori_usdt = get_invest_params(3).to_f  # 原有参与投资的泰达币
      factor = get_invest_params(4).to_f    # 单笔买入价格调整参数
      price_diff = price_now - bottom
      # 现价 > 破底价 --> 价格越低，投资越多
      if price_now - bottom > 1
          return ((ori_usdt/(price_diff/100)**2)*factor)*$usdt_to_cny
      # 现价 < 破底价 --> 直接以最大投资额购买
      else
          return max_invest_cny
      end
    end

    # 计算以现价购买的单笔最大投资金额
    def max_invest_cny
      max_usdt = get_invest_params(8).to_f  # 单笔买入泰达币最大值
      return max_usdt*$usdt_to_cny
    end

end
