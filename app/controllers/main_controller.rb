class MainController < ApplicationController

  # 显示走势图
  def chart
    build_fusion_chart_data(get_class_name_by_login,1)
    render template: 'shared/chart'
  end

  # 显示登入表单及接受登入表单
  def login
    if correct_pincode? and admin?
      redirect_to portfolios_path
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
    update_all_huobi_assets
    go_back
  end

  # 更新火币交易记录
  def update_huobi_records
    update_huobi_deal_records
    go_back
  end

  # 火币下单确认页
  def place_order_confirm
    if deal_record = DealRecord.find(params[:id])
      @amount = deal_record.real_amount.floor(6)
      if params[:type] == 'earn'
        @price = deal_record.earn_limit_price
      elsif params[:type] == 'loss'
        @price = deal_record.loss_limit_price
      end
    end
  end

  # 执行火币下单
  def place_order
    root = eval("@huobi_api_#{params[:account]}").new_order(params[:symbol],params[:type],params[:price],params[:amount])
    if root["status"] == "ok" and order_id = root["data"] and !order_id.empty?
      put_notice "#{t(:place_order_ok)} #{t(:deal_record_order_id)}: #{order_id}"
    else
      put_notice t(:place_order_failure)
    end
    go_deal_records
  end

end
