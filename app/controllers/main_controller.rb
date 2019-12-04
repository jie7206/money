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
    redirect_to '/?tags=170'
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
      session[:deal_record_id] = params[:id]
      if deal_record = DealRecord.find(session[:deal_record_id])
        @amount = deal_record.real_amount.floor(6)
        if params[:type] == 'earn'
          @price = deal_record.earn_limit_price
        elsif params[:type] == 'loss'
          @price = deal_record.loss_limit_price
        end
      end
    elsif params[:amount]
      @amount = params[:amount].to_f
      @price = btc_price
    else
      @price = btc_price
    end
    @btc_level = to_n(DealRecord.btc_level) # 显示目前仓位
  end

  # 执行下单试算
  def order_calculate
    put_notice 'OK!'
    redirect_to place_order_form_path
  end

  # 执行火币下单
  def place_order
    put_notice 'Test Place Order OK!'
    # root = @huobi_api_170.new_order(params[:symbol],params[:type],params[:price],params[:amount])
    # if root["status"] == "ok" and order_id = root["data"] and !order_id.empty?
    #   DealRecord.find(session[:deal_record_id]).update_attribute(:order_id,order_id)
    #   put_notice "#{t(:place_order_ok)} #{t(:deal_record_order_id)}: #{order_id}"
    #   session.delete(:deal_record_id)
    # else
    #   put_notice t(:place_order_failure)
    # end
    go_deal_records
  end

  # 查看火币下单情况
  def look_order
    root = @huobi_api_170.order_status(params[:id])
    render :json => root
  end

  # 取消火币下单
  def del_huobi_orders
    order_id = params[:order_id]
    root = @huobi_api_170.submitcancel(order_id)
    if root["status"] == "ok"
      DealRecord.find_by_order_id(order_id).clear_order
      put_notice t(:cancel_order_ok)
    end
    go_deal_records
  end

  # API测试
  def get_huobi_assets_test
    root = @huobi_api_170.balances
    respond_to do |format|
      format.json  { render :json => root }
    end
  end

  # 返回K线数据（蜡烛图）
  def get_kline
    symbol = params[:symbol] ? params[:symbol] : "btcusdt"
    period = params[:period] ? params[:period] : "5min"
    size = params[:size] ? params[:size] : 200
    @symbol_title = symbol_title(symbol)
    @period_title = period_title(period)
    begin
      root = JSON.parse(`python btc_price.py symbol=#{symbol} period=#{period}  size=#{size}`)
      return root["data"].reverse! if root["data"] and root["data"][0]
    rescue
      return []
    end
  end

  # 显示K线图
  def kline_chart
    @raw_data = get_kline
    if @raw_data and @raw_data.size > 0
      @page_title = "#{@symbol_title} #{@period_title}K线走势图"
      @timestamp = get_timestamp
      # 建构K线图副标题
      ma_str = ""
      [5,10,20,30,60].each do |n|
        ma_str += " MA#{n}: #{ma(n)}(#{pom(n)}%)"
      end
      buy_amount, sell_amount, buy_sell_rate = cal_buy_sell
      @subcaption = "收: #{@raw_data[-1]["close"]} 高: #{@raw_data[-1]["high"]} 低: #{@raw_data[-1]["low"]} 中: #{mid(@raw_data[-1]["high"],@raw_data[-1]["low"])}#{ma_str} 买: #{buy_amount} 卖: #{sell_amount} 比: #{buy_sell_rate}"
      render :layout => nil
    else
      return false
    end
  end

  # 计算中间价
  def mid(high, low)
    return format("%.2f",(high.to_f+low.to_f)/2).to_f
  end

  # 计算买卖量
  def cal_buy_sell(data=@raw_data)
    buy_amount = sell_amount = 0
    data.each do |item|
      buy_amount += item["amount"].to_f if item["close"].to_f >= item["open"].to_f
      sell_amount += item["amount"].to_f if item["close"].to_f < item["open"].to_f
    end
    return buy_amount.to_i, sell_amount.to_i, format("%.2f",buy_amount/sell_amount)
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

  # 如果没有负号，在前面显示+号
  def add_plus(str)
    if !str.index("-")
      return "+"+str
    else
      return str
    end
  end

end
