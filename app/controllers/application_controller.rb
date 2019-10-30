class ApplicationController < ActionController::Base

  include ApplicationHelper

  before_action :check_login, except: [ :login ]

  # 初始化设置
  def initialize
    super
    load_global_variables
    Currency.add_or_renew_ex_rates # 方便汇率转换直接调用，无需再次查询数据库
  end

  # 读入网站所有的全局参数设定
  def load_global_variables
    eval File.open("#{Rails.root}/config/global_variables.txt",'r').read
  end

  # 所有页面需要输入PIN码登入之后才能使用
  def check_login
    redirect_to login_path if !login?
  end

  # 显示当前时间
  def now
    Time.now.to_s(:db)
  end

  # 显示通知讯息
  def put_notice( string )
    flash[:notice] = "#{string} (#{now})"
  end

  # 显示资产时是否包含显示隐藏资产
  def admin_hash?( new_options = {} )
    options = admin? ? {include_hidden: true} : {include_hidden: false}
    return options.merge new_options
  end

  # 建立回到目录页的方法
  "property,currency,interest".split(',').each do |n|
    define_method "go_#{n.pluralize}" do
      eval("redirect_to controller: :#{n.pluralize}, action: :index")
    end
  end

end
