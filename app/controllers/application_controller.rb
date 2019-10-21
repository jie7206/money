class ApplicationController < ActionController::Base

  include ApplicationHelper

  before_action :check_login, except: [ :login ]

  # 初始化设置
  def initialize
    super
    load_global_variables
  end

  # 读入网站所有的全局参数设定
  def load_global_variables
    $site_logo = 'money.jpg'
    $property_name_maxlength = 30
    $site_name = t(:site_name)
    $login_error_message = t(:login_err_msg)
    $property_name_error_by_blank = t(:property_name_error_by_blank)
    $property_name_error_by_length = t(:property_name_error_by_length)
    $property_amount_error_by_blank = t(:property_amount_error_by_blank)
    $property_amount_error_by_numeric = t(:property_amount_error_by_numeric)
    eval(File.open("#{Rails.root}/config/global_variables.txt",'r').read)
  end

  # 所有页面需要输入PIN码登入之后才能使用
  def check_login
    redirect_to login_path if !login?
  end

  # 回到资产目录页
  def go_properties
    redirect_to controller: :properties, action: :index
  end

  # 显示当前时间
  def now
    Time.now.to_s(:db)
  end

  # 显示通知讯息
  def put_notice( string )
    flash[:notice] = "#{string} (#{now})"
  end

end
