class MainController < ApplicationController

  # 默认首页
  def index
  end

  # 显示登入表单及接受登入表单
  def login
    if correct_pincode? then redirect_to root_path end
  end

  # 执行登出
  def logout
    session[:login] = false
    redirect_to login_path
  end

  # 验证输入的PIN码是否正确
  def correct_pincode?
    if input_pincode? and params[:pincode] == $pincode
      session[:login] = true
      return true
    elsif input_pincode?
      flash.now[:warning] = $login_error_message
      return false
    end
  end

  # 是否有从表单输入PIN值
  def input_pincode?
    params[:pincode] and !params[:pincode].empty?
  end

end
