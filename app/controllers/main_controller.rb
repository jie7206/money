require 'json'

class MainController < ApplicationController

  include ActionView::Helpers::OutputSafetyHelper # 为了使用 raw

  skip_before_action :verify_authenticity_token, :only => [:order_calculate, :place_order]

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

  # 显示资产净值走势图
  def net_chart
    build_fusion_chart_data(get_class_name_by_login,1)
    render template: 'shared/chart'
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
    if params[:keep_level] # 仓位恒定投资法
      keep = $btc_base_level.to_f/100 # 想要保持的基准仓位
      level = Property.btc_level/100 # BTC总仓位值
      capital = Property.total_investable_fund_records_usdt # 跨账号所有可投资金台币现值
      amount = Property.btc_amount # BTC总数
      value = Property.total_flow_assets_usdt # 跨账号流动性资产总值USDT现值
      price = btc_price # BTC现价
      fee_rate = $fees_rate # 交易手续费率
      # 如果仓位小于保持仓位且还有剩余资金则买进
      if (keep-level) > 0 and capital > 0
        # 计算用多少USDT购买
        usdt = value*(keep-level)
        # 买入的单位数
        unit = usdt/price
        unit = buy_amount_to_keep_level capital, amount, keep, price, fee_rate
        @deal_type = 'buy-limit'
      end
      # 如果仓位大于保持仓位且还有剩余BTC则卖出
      if (level-keep) > 0 and amount > 0
        # 计算要卖出多少USDT
        usdt = value*(level-keep)
        # 卖出的单位数
        unit = sell_amount_to_keep_level capital, amount, keep, price
        @deal_type = 'sell-limit'
      end
      @amount = unit.floor(6)
      @price = price
    elsif params[:id]
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

  # 显示原始报价数据
  def kline_data
    render json: get_kline
  end

  # 检查是否超过火币WebSocket所能容许的查询期间
  # 1min, 5min, 15min, 30min, 60min, 4hour, 1day, 1mon, 1week, 1year
  def get_kline_time( from_time, to_time, period = '60min', max_size = 300 )
    next_from_time = nil # 如果没取完，下次开始的时间
    sec_num = 0 # 各期间所对应的秒数
    case period
      when '1min'
        sec_num = 60
      when '5min'
        sec_num = 60*5
      when '15min'
        sec_num = 60*15
      when '30min'
        sec_num = 60*30
      when '60min'
        sec_num = 60*60
      when '4hour'
        sec_num = 60*60*4
      when '1day'
        sec_num = 60*60*24
      when '1week'
        sec_num = 60*60*24*7
      when '1mon'
        sec_num = 60*60*24*30
      when '1year'
        sec_num = 60*60*24*365
    end
    from_time_num = from_time.to_time.to_i
    to_time_num = to_time.to_time.to_i
    max_to_time_num = from_time_num + sec_num*max_size
    if to_time_num > max_to_time_num
      to_time_num = max_to_time_num
      next_from_time = Time.at(max_to_time_num).to_s(:db)
    end
    return from_time_num, to_time_num, next_from_time
  end

  # 储存原始报价数据
  def save_kline_data
    symbol = $kline_data_symbol
    period = $kline_data_period
    get_from_time = $kline_data_from
    get_to_time = $kline_data_to
    count = 0
    while true
      from_time, to_time, next_from_time = \
        get_kline_time(get_from_time,get_to_time,period)
      raw_data = get_kline(period,0,symbol,from_time,to_time).reverse
      if raw_data.size > 0
        raw_data.each do |d|
          if not LineData.find_repeat(symbol,period,d["id"])
            LineData.create(
              symbol: symbol,
              period: period,
              tid: d["id"],
              open: d["open"],
              close: d["close"],
              high: d["high"],
              low: d["low"],
              vol: d["vol"].floor(4),
              amount: d["amount"].floor(4),
              count: d["count"]
            )
            count += 1
          end
        end
      end
      if next_from_time != nil
        get_from_time = next_from_time
      else
        break
      end
    end
    flash.now[:notice] = "已将#{count}笔#{symbol}(#{period})的数据存入数据库！(#{now})"
    @text = <<-EOF
              如有需要，请到系统参数页面修改下列参数后执行:
              <ol>
                <li>$kline_data_period = '#{$kline_data_period}'</li>
                <li>$kline_data_symbol = '#{$kline_data_symbol}'</li>
                <li>$kline_data_from = '#{$kline_data_from}'</li>
                <li>$kline_data_to = '#{$kline_data_to}'</li>
              </ol>
    EOF
    render template: 'shared/blank'
  end

  # 取得报价资料
  def get_price_data( options = {} )
    if options[:local_db] == true
      return get_kline_db($mt_from, $mt_to, $mt_period)
    else
      if !$mt_from.empty? and !$mt_to.empty?
        result = []
        get_from_time = $mt_from
        while true
          from_time, to_time, next_from_time = \
            get_kline_time(get_from_time,$mt_to,$mt_period)
          result += get_kline($mt_period,0,'btcusdt',from_time,to_time).reverse
          if next_from_time != nil
            get_from_time = next_from_time
          else
            break
          end
        end
        return result
      else
        return get_kline($mt_period,$mt_size)
      end
    end
  end

  # 以50对比的数学模型测试自动买卖是否能盈利
  def model_trade_test_set
    message = ""
    # 本地数据库过慢，必须是只测试一次才行
    if $mts_use_local_db
      price_data = get_price_data(local_db: true)
    else
      price_data = get_price_data
    end
    $mt_dv_range.each do |dv| # 仓位阀值
      $mt_size_range.each do |pn| # 计算的报价笔数
        message += model_trade_core(price_data,false,dv,pn)
      end
    end
    write_mtrades_log message
    set_mt_page_content t(:model_trade_set), mtrades_path, message
    render template: 'shared/blank'
  end

  # 显示以50对比的数学模型测试结果
  def show_mtrades_log
    set_mt_page_content t(:model_trade_set), mtrades_path, read_mtrades_log
    render template: 'shared/blank'
  end

  # 以50对比的数学模型测试自动买卖是否能盈利
  def model_trade_test_single
    # 本地数据库过慢，必须是只测试一次才行
    if !$mts_random_date and $mts_use_local_db
      price_data = get_price_data(local_db: true)
    else
      price_data = get_price_data
    end
    message = model_trade_core(price_data)
    write_mtrade_log message
    set_mt_page_content t(:model_trade_single), mtrade_path, message
    render template: 'shared/blank'
  end

  # 显示以50对比的数学模型测试结果
  def show_mtrade_log
    set_mt_page_content t(:model_trade_single), mtrade_path, read_mtrade_log
    render template: 'shared/blank'
  end

  # 计算要显示的BTC走势图资料笔数
  def cal_mts_data_size
    if !$mt_from_date.empty? and !$mt_to_date.empty?
      end_date = $mt_to_date.to_date > Date.today ? Date.today : $mt_to_date
      return day_diff($mt_from_date,end_date)
    else
      return 30*3
    end
  end

  # 以50对比的数学模型核心程序(dv=仓位阀值,pn=计算的报价笔数)
  def model_trade_core( raw_data, show_msg = true, dv = 0, pn = 0 )

    message = "" # 回传显示讯息
    data_size = raw_data.size

    if data_size > 0

      cal_price_size = pn > 0 ? pn : $mts_cal_size_value # 要计算的报价笔数
      set_diff_value = dv > 0 ? dv : $mts_set_diff_value # 仓位至少相差多少才动作
      total_test_count = total_neg_count = total_neg_count_btc = 0 # 计算总平均亏损率用
      cap_rates_max = 0 ; cap_rates_min = 100 # 为了找出资产利率最大值与最小值
      btc_rates_max = 0 ; btc_rates_min = 100 # 为了找出币数利率最大值与最小值
      total_operate_count = 0 # 计算操作次数
      # 为了找出计算数据日期的最大值与最小值
      cal_begin_date = to_d(Date.today,false,true)
      cal_end_date = ""
      # 如果不使用随机日期，则模型单测只测试一次
      mts_already_run = false

      (1..$mt_cal_loop).each do

        # 如果不使用随机日期，则模型单测只测试一次
        break if !$mts_random_date and mts_already_run

        neg_count = 0 # 资产亏损的次数
        neg_count_btc = 0 # 币数亏损的次数
        capital_rate_max = 0 ; capital_rate_min = 100 # 资产利率的最大值与最小值记录
        amount_rate_max = 0 ; amount_rate_min = 100 # 币数利率的最大值与最小值记录
        total_buy_count = 0 # 记录总买进次数
        total_sell_count = 0 # 记录总卖出次数

        (1..$mt_loop_num).each do

          # 如果不使用随机日期，则模型单测只测试一次
          break if !$mts_random_date and mts_already_run

          # 初始化参数
          capital = ori_capital = 10000 # 投入资金(USDT)
          amount = start_amount = 0 # 持有的比特币数量
          start_amount_flag = false # 比特币初始量旗标
          keep = $mt_keep_level # 保持比特币仓位
          diff = set_diff_value # 仓位至少相差多少才动作
          value = capital # 资产总值(USDT)

          start_time = nil # 开始计算的时间
          end_time = nil # 结束计算的时间
          start_time_flag = false # 开始计算的时间旗标
          time = nil # 最新计算的时间

          buy_count = 0 # 记录买进次数
          sell_count = 0 # 记录卖出次数

          if !show_msg or $mts_random_date # 总测 或 单测使用随机日期多笔测试
            # 避免超出索引
            if cal_price_size > data_size or cal_price_size > data_size - $mt_size_fix
              cal_price_size = data_size - $mt_size_fix
            end
            prices = raw_data[rand(0..(data_size-cal_price_size)),cal_price_size]
          else
            prices = raw_data
            mts_already_run = true
          end
          prices.each do |d|
            begin
              time = Time.at(d.tid)
            rescue
              time = Time.at(d["id"])
            end
            time_str = to_d(time,false,true)
            # 是否计算全部数据
            cal_all = ($mt_from_date.empty? or $mt_to_date.empty?) ? true : false
            # 挑选日期区间计算
            from_date, to_date = $mt_from_date, $mt_to_date
            if cal_all or (time >= from_date.to_time and time <= to_date.to_time)
              if !start_time_flag
                start_time = time
                start_time_flag = true
                cal_begin_date = time_str if time_str < cal_begin_date
              end
              end_time = time
              cal_end_date = time_str if time_str > cal_end_date
              begin
                price = d.close
              rescue
                price = d["close"]
              end
              # 计算比特币仓位
              level = amount*price/value
              # 如果仓位小于保持仓位且还有剩余资金则买进
              if (keep-level) > diff and capital > 0
                # 买入的单位数
                unit = buy_amount_to_keep_level capital, amount, keep, price, $mt_fee_rate
                # 计算用多少USDT购买
                usdt = price*unit
                # 实际购得的比特币数
                unit = unit * (1-$mt_fee_rate)
                # 比特币初始量
                if !start_amount_flag
                  start_amount = unit
                  start_amount_flag = true
                end
                # 累计的单位数
                amount += unit
                # 更新资金余额
                capital -= usdt
                # 更新资产总值
                value = capital + amount*price
                # 更新比特币仓位
                level_after = amount*price/value
                # 交易摘要
                trade_info = <<-EOF
                          #{to_t(time)}
                          现价：#{add_zero(price.to_i,5)}
                          仓位：#{add_zero(to_n(level*100,0))}%
                          买入：#{to_n(unit,3)}
                          总数：#{to_n(amount,3)}
                          仓位：#{add_zero(to_n(level_after*100,1))}%
                          花费：#{add_zero(usdt.to_i,4)}
                          余额：#{add_zero(capital.to_i,4)}
                          总值：#{add_zero(value.to_i,5)}<br/>
                EOF
                buy_count += 1
                total_buy_count += 1
                total_operate_count += 1
                message += trade_info if !$mts_random_date
              end
              # 如果仓位大于保持仓位且还有剩余BTC则卖出
              if (level-keep) > diff and amount > 0
                # 卖出的单位数
                unit = sell_amount_to_keep_level capital, amount, keep, price
                # 计算要卖出多少USDT
                usdt = price*unit
                # 累计的单位数
                amount -= unit
                # 更新资金余额
                capital += usdt*(1-$mt_fee_rate)
                # 更新资产总值
                value = capital + amount*price
                # 更新比特币仓位
                level_after = amount*price/value
                # 交易摘要
                trade_info = <<-EOF
                          #{to_t(time)}
                          现价：#{add_zero(price.to_i,5)}
                          仓位：#{add_zero(to_n(level*100,0))}%
                          卖出：#{to_n(unit,3)}
                          总数：#{to_n(amount,3)}
                          仓位：#{add_zero(to_n(level_after*100,1))}%
                          进账：#{add_zero(usdt.to_i,4)}
                          余额：#{add_zero(capital.to_i,4)}
                          总值：#{add_zero(value.to_i,5)}<br/>
                EOF
                sell_count += 1
                total_sell_count += 1
                total_operate_count += 1
                message += trade_info if !$mts_random_date
              end
            end # end cal_all
          end # end prices.each

          # 加一条水平线比较美观
          message += "<hr/>" if total_operate_count > 0

          # 计算利率
          cap_rate = value/ori_capital*100 if ori_capital > 0
          btc_rate = amount/start_amount*100 if start_amount > 0

          # 记录资产亏损的次数
          if value < ori_capital
            neg_count += 1
            total_neg_count += 1
          end
          # 记录币数亏损的次数
          if amount < start_amount
            neg_count_btc += 1
            total_neg_count_btc += 1
          end
          # 记录资产利率的最大值与最小值
          capital_rate_max = cap_rate if cap_rate > capital_rate_max
          capital_rate_min = cap_rate if cap_rate < capital_rate_min
          cap_rates_max = cap_rate if cap_rate > cap_rates_max
          cap_rates_min = cap_rate if cap_rate < cap_rates_min
          # 记录币数利率的最大值与最小值
          amount_rate_max = btc_rate if btc_rate > amount_rate_max
          amount_rate_min = btc_rate if btc_rate < amount_rate_min
          btc_rates_max = btc_rate if btc_rate > btc_rates_max
          btc_rates_min = btc_rate if btc_rate < btc_rates_min

          # 测试总次数
          total_test_count += 1
          puts "pn: #{pn} dv: #{dv} count: #{total_test_count}"

          if show_msg and start_time_flag
            message += "持仓:#{$mt_keep_level*100}% 阀值:#{to_n(set_diff_value*100,2)}% 区间:#{$mt_period} 间隔:#{add_zero(day_diff(start_time,end_time),3)}天 #{to_d(start_time,true)} → #{to_d(end_time,true)} 资产:#{ori_capital.to_i} → #{value.to_i}(#{add_zero(to_n(cap_rate,2),3)}%) 币数:#{to_n(start_amount,8)} → #{to_n(amount,8)}(#{add_zero(to_n(btc_rate,2),3)}%) 买/卖:#{add_zero(buy_count,3)}/#{add_zero(sell_count,3)}/#{buy_count+sell_count}<br/>"
          end

        end # end $mt_loop_num

        neg_rate = neg_count.to_f/$mt_loop_num*100 # 资产亏损率
        neg_rate_btc = neg_count_btc.to_f/$mt_loop_num*100 # 币数亏损率

        if show_msg and $mts_random_date
          message += "<hr/>测试次数:#{$mt_loop_num} 资产亏损次数:#{neg_count} 资产平均亏损率:#{to_n(neg_rate)}% 币数亏损次数:#{neg_count_btc} 币数平均亏损率:#{to_n(neg_rate_btc)}% 资产:#{to_n(capital_rate_min)}% → #{to_n(capital_rate_max)}% 币数:#{to_n(amount_rate_min)}% → #{to_n(amount_rate_max)}% 买/卖:#{total_buy_count}/#{total_sell_count}/#{total_buy_count+total_sell_count}<hr/>"
        elsif show_msg and !$mts_random_date
          message += "<hr/>"
        end
      end # end $mt_cal_loop
      # 修正单测时操作比例计算错误问题
      if show_msg and !$mts_random_date
        operate_rate = total_operate_count.to_f/data_size*100
      else
        operate_rate = total_operate_count.to_f/(cal_price_size*total_test_count)*100
      end
      info = "持仓:#{($mt_keep_level*100).to_i}%(#{to_n(set_diff_value*100,2)}%) #{$mt_period} #{add_zero(cal_price_size,4)}笔"
      summary = "#{cal_begin_date}-#{cal_end_date} 测#{add_zero(total_test_count,4)}次 操作#{add_zero(total_operate_count,5)}次(#{add_zero(to_n(operate_rate,0),2)}%) 资亏#{add_zero(total_neg_count,4)}次(#{add_zero(to_n(total_neg_count.to_f/total_test_count*100,0),3)}%) 币亏#{add_zero(total_neg_count_btc,4)}次(#{add_zero(to_n(total_neg_count_btc.to_f/total_test_count*100,0),3)}%) 资产% #{add_zero(to_n(cap_rates_min,0),3)}→#{add_zero(to_n(cap_rates_max,0),3)} 币数% #{add_zero(to_n(btc_rates_min,0),3)}→#{add_zero(to_n(btc_rates_max,0),3)}"
      if show_msg
        message += "#{summary}<hr/>"
      else
        message = "#{info} #{summary}<br/>"
      end
    else
      message = "无法读取报价(数据笔数为0)，请检查数据来源或稍后再试！"
    end # end raw_data.size > 0

    return message
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

  # 建立仓位试算表预先知道多少价格买进或卖出多少数量以提前准备
  def level_trial_list
    @price_now = get_price_now
    @keep = $btc_base_level # 想要保持的基准仓位
    @fund_usdt = Property.total_investable_fund_records_usdt # 跨账号所有可投资金USDT现值
    @btc_amount = Property.btc_amount # 比特币总数
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
