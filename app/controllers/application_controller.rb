class ApplicationController < ActionController::Base

  include ApplicationHelper

  #before_action :check_login, except: [ :login ]

  $site_name = '我的网站'

  # 初始化设置
  def initialize
    super
    load_global_variables
  end

  # 读入网站所有的全局参数设定
  def load_global_variables
    eval(File.open("#{Rails.root}/config/global_variables.txt",'r').read)
  end

  # 所有页面需要输入PIN码登入之后才能使用
  def check_login
    redirect_to login_path if !login?
  end

end
