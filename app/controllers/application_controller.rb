class ApplicationController < ActionController::Base

  include ApplicationHelper

  before_action :check_login, except: [ :login ]

  # 火币API初始化
  def ini_huobi( id = '1' )
    eval("@huobi_api = Huobi.new($acckey_#{id},$seckey_#{id},$accid_#{id},$huobi_server)")
  end

  # 初始化设置
  def initialize
    super
    load_global_variables
    ini_huobi # 初始化火币API
    Currency.add_or_renew_ex_rates # 方便汇率转换直接调用，无需再次查询数据库
  end

  # 读入网站所有的全局参数设定
  def load_global_variables
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

  # 显示当前时间
  def now
    Time.now.strftime("%H:%M")
  end

  # 显示资产时是否包含显示隐藏资产
  def admin_hash?( new_options = {} )
    options = admin? ? {include_hidden: true} : {include_hidden: false}
    return options.merge new_options
  end

  # 从火币网取得某一数字货币的最新报价
  def get_huobi_price( symbol )
    begin
      Timeout.timeout(90) do
        if @huobi_api
          root = @huobi_api.history_kline(symbol.to_s,'1min',1)
          if root["data"] and root["data"][0] # 不管什么情况，如果发生异常，则返回0
            return format("%.4f",root["data"][0]["close"]).to_f
          end
        end
      end
    rescue
      return 0
    end
  end

  # 更新所有数字货币的汇率值
  def update_digital_exchange_rates
    count = 0
    # 必须先更新USDT的汇率，其他的报价换算成美元才能准确
    usdt = Currency.usdt
    if usdt_price = get_huobi_price(usdt.symbol) and usdt_price > 0
      update_exchange_rate(usdt.code,(1/usdt_price).floor(8))
      count += 1
      Currency.digitals.each do |c|
        next if c.code == 'USDT'
        if price = get_huobi_price(c.symbol) and price > 0
          update_exchange_rate(c.code,(1/(price*usdt_price)).floor(8))
          count += 1
        end
      end
    end
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
    return count
  end

  # 取得SSL连线的回传值
  def get_ssl_response(url, authorization=nil)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    header = {'Authorization':authorization}
    response = http.get(url, header)
    return response.body
  end

  # 取得最新法币汇率的报价
  def get_exchange_rate(fromCode, toCode)
    url = "https://ali-waihui.showapi.com/waihui-transform?fromCode=#{fromCode.to_s.upcase}&toCode=#{toCode.to_s.upcase}&money=1"
    resp = get_ssl_response(url,"APPCODE de9f4a29c5eb4c73b0be619872e18857")
    if rate = Regexp.new(/(\d)+\.(\d)+/).match(resp)
      return rate[0].to_f
    else
      return 0
    end
  end

  # 更新单一法币的汇率值
  def update_exchange_rate( code, value )
    if currency = Currency.find_by_code(code)
      currency.update_attribute(:exchange_rate,value)
      return value
    end
  end

  # 记录返回的网址
  def memory_back
    if params[:tags]
      session[:path] = request.fullpath
    elsif params[:path]
      session[:path] = params[:path]
    end
  end

  # 返回记录的网址
  def go_back
    if params[:path]
      redirect_to params[:path]
    elsif session[:path]
      redirect_to session[:path]
      session.delete(:path)
    end
  end

  # 在通知讯息后面加上物件的ID
  def add_id( object )
    " ID: #{object.id}"
  end

  # 从标签设定值取出相应的资产数据集
  def get_properties_from_tags( include_tags, exclude_tags = nil, mode = 'n' )
    case mode
      when 'n' # none
        options = {}
      when 'm' # match_all
        options = {match_all: true}
      when 'a' # any
        options = {any: true}
    end
    # 依照包含标签选取
    if include_tags and !include_tags.empty?
      result = Property.tagged_with(include_tags.strip.split(' '),options)
      if exclude_tags and !exclude_tags.empty?
        # 依照排除标签排除
        result = result.tagged_with(exclude_tags.strip.split(' '),exclude: true)
      end
      return result
    end
    return nil
  end

  # 更新所有的资产组合栏位数据
  def update_all_portfolio_attributes
    Portfolio.all.each do |p|
      properties = get_properties_from_tags(p.include_tags,p.exclude_tags,p.mode)
      update_portfolio_attributes(p.id, properties)
    end
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
  def summary
    @show_summary = true
    @properties_net_value_twd = Property.net_value :twd, admin_hash?
    @properties_net_value_cny = Property.net_value :cny, admin_hash?
    @properties_lixi_twd = Property.lixi :twd, admin_hash?
    @properties_value_twd = Property.value :twd, admin_hash?(only_positive: true)
    @properties_loan_twd = Property.value :twd, admin_hash?(only_negative: true)
    @properties_net_growth_ave_month = Property.net_growth_ave_month :twd, admin_hash?
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
        flash[:#{type}] ? flash[:#{type}].gsub!(\"(\#{now})\",'　') : flash[:#{type}] = ''
        flash[:#{type}] += \"\#{msg} (\#{now})\"
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
            @#{m}.update_attribute(:#{a}, new_#{a})
            put_notice t(:#{m}_updated_ok) + add_id(@#{m})
          end
          session[:path] ? go_back : go_#{m.pluralize}
        ]
      end
    end
  end

end
