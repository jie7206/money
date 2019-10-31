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

  # 显示当前时间
  def now
    Time.now.strftime("%H:%M")
  end

  # 显示通知讯息
  def put_notice( string )
    flash[:notice] ? flash[:notice].gsub!("(#{now})",' ') : flash[:notice] = ''
    flash[:notice] += "#{string} (#{now}) "
  end

  # 显示资产时是否包含显示隐藏资产
  def admin_hash?( new_options = {} )
    options = admin? ? {include_hidden: true} : {include_hidden: false}
    return options.merge new_options
  end

  # 读取比特币最新报价
  def get_btc_price
    if @huobi_api
      root = @huobi_api.history_kline('btcusdt','1min',1)
      if root["data"] and root["data"][0] # 不管什么情况，如果发生异常，则返回0
        return format("%.2f",root["data"][0]["close"]).to_f
      end
    end
    return 0
  end

  # 建立回到目录页的方法
  "property,currency,interest".split(',').each do |n|
    define_method "go_#{n.pluralize}" do
      eval("redirect_to controller: :#{n.pluralize}, action: :index")
    end
  end

###############################################################################

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
    Currency.find_by_code(code).update_attribute(:exchange_rate,value)
  end

  # 更新所有法币的汇率值(除了比特币和美元以外)
  def update_legal_exchange_rates
    count = 0
    (Currency.all.map {|c| c.code} - [:usd, :btc].map {|c| c.to_s.upcase}).each do |code|
      if value = get_exchange_rate(:usd,code) and value > 0
        update_exchange_rate( code, value )
        count += 1
      end
    end
    return count
  end

end
