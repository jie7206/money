class DealRecordsController < ApplicationController

  # before_action :check_admin
  before_action :set_deal_record, only: [:edit, :update, :destroy, :delete, :switch_first_sell, :switch_to_trezor, :switch_to_balance]

  def index
    if params[:show_all]
      @deal_records = DealRecord.where("account = '#{get_huobi_acc_id}'").order('created_at  desc')
    elsif params[:show_sell]
      @deal_records = DealRecord.where("auto_sell = 1 and real_profit != 0 and account = '#{get_huobi_acc_id}'").order('updated_at desc').limit($sell_records_limit)
    elsif params[:show_unsell]
      order_field = params[:order_field] ? params[:order_field] : 'price'
      @deal_records = DealRecord.where("auto_sell = 0 and account = '#{get_huobi_acc_id}'").order('first_sell desc,price')
    elsif params[:make_balance_count]
      @deal_records = make_balance_count_records
    elsif params[:make_trezor_count]
      @deal_records = make_trezor_count_records
    elsif params[:show_first]
      @deal_records = DealRecord.where("first_sell = 1 and auto_sell = 0 and account = '#{get_huobi_acc_id}'").order('created_at desc')
    elsif params[:show_balance]
      @deal_records = DealRecord.where("auto_sell = 1 and real_profit = 0.01 and account = '#{get_huobi_acc_id}'").order('amount')
    elsif params[:show_trezor]
      @deal_records = DealRecord.where("auto_sell = 1 and real_profit = 0 and account = '#{get_huobi_acc_id}'").order('created_at desc')
    else
      @deal_records = DealRecord.where("auto_sell = 0 and account = '#{get_huobi_acc_id}'").order('created_at desc')
    end
    summary
    @get_max_sell_count = get_max_sell_count
    @price_now, @buy_amount, @sell_amount, @buy_sell_rate = cal_buy_sell_rate
    update_btc_price(@price_now) if @price_now > 0 and $auto_update_btc_price > 0
    update_huobi_assets_core if $auto_update_huobi_assets > 0
    setup_auto_refresh_sec
  end

  def new
    @deal_record = DealRecord.new
  end

  def edit
  end

  def create
    @deal_record = DealRecord.new(deal_record_params)
    if @deal_record.save
      put_notice t(:deal_record_created_ok)
      go_deal_records
    else
      render :new
    end
  end

  def update
    if @deal_record.update(deal_record_params)
      put_notice t(:deal_record_updated_ok)
      go_deal_records
    else
      render :edit
    end
  end

  def update_deal_records
    put_notice `python py/deal_records.py`
    go_deal_records
  end

  def destroy
    @deal_record.destroy
    put_notice t(:deal_record_destroyed_ok)
    go_deal_records
  end

  def delete
    destroy
  end

  def delete_invest_log
    text = nil
    if $keep_invest_log_num and $keep_invest_log_num > 0
      content = File.read($auto_invest_log_path)
      line = $log_split_line
      if content.include? line
        text = line+content.split(line).reverse[0..($keep_invest_log_num-1)].reverse.join(line)
      end
    end
    if File.exist? $auto_invest_log_path
        File.delete $auto_invest_log_path
        if text
          File.open($auto_invest_log_path, 'w+') do |f|
            f.write(text)
          end
          put_notice t(:clear_invest_log_and_keep)+$keep_invest_log_num.to_s+t(:bi)
        else
          File.new $auto_invest_log_path, 'w+'
          put_notice t(:delete_invest_log_ok)
        end
    end
    redirect_to invest_log_path
  end

  # 清空交易记录
  def clear
    put_notice t(:clear_deal_records_ok) + "(#{DealRecord.clear_unsell_records}#{t(:bi)})"
    go_deal_records
  end

  # 压缩卖出记录将所有的卖出记录累计成一笔
  def zip_sell_records
    price = amount = real_profit = 0
    rs = DealRecord.sell_records.order('created_at')
    keep_id = rs.last.id
    count = rs.size
    rs.each do |r|
      price += r.price * r.amount
      amount += r.amount
      real_profit += r.real_profit
      r.destroy if r.id != keep_id
    end
    price = (price/amount).round(2)
    DealRecord.find(keep_id).update_attributes(
      price: price,
      amount: amount,
      real_profit: real_profit
    )
    put_notice t(:zip_sell_records_ok) + "(#{count}#{t(:bi)})"
    go_deal_records
  end

  # 执行卖出下单以弥补自动交易买入后延迟卖出的不足
  def send_sell_deal_records
    below_price = get_invest_params(1).to_f
    profit = get_invest_params(12).to_f
    max_sell_count = get_invest_params(13).to_i
    if max_sell_count > 0 and DealRecord.profit_cny > profit
      setup_sell_params
      put_notice t(:send_sell_deal_records_ok)
      sleep $wait_send_sec
      redirect_to invest_log_path
    else
      put_notice t(:send_sell_deal_records_error)+"(¥#{profit.to_i})"
      go_deal_records
    end
  end

  # 交易列表新增执行停损功能
  def send_stop_loss
    if DealRecord.over_sell_time?
      setup_sell_params
      put_notice t(:send_stop_loss_ok)
      sleep $wait_send_sec
      redirect_to invest_log_path
    else
      put_notice t(:send_stop_loss_error)
      go_back
    end
  end

  # 交易列表新增执行买入功能
  def send_force_buy
    if DealRecord.over_buy_time?
      setup_buy_params
      put_notice t(:send_force_buy_ok)
      sleep $wait_send_sec
      redirect_to invest_log_path
    else
      put_notice t(:send_force_buy_error)
      go_back
    end
  end

  # 交易列表新增卖到回本功能
  def sell_to_back
    ori_goal = get_invest_params(12)
    ori_count = get_invest_params(13)
    set_invest_params(12,'1000000')
    set_invest_params(13,DealRecord.unsell_count.to_s)
    setup_sell_params
    put_notice t(:sell_to_back_ok)
    sleep $wait_send_sec
    set_invest_params(12,ori_goal)
    set_invest_params(13,ori_count)
    redirect_to invest_log_path
  end

  # 切换标示优先卖出
  def switch_first_sell
    if @deal_record.first_sell
      @deal_record.update_attribute(:first_sell,nil)
    else
      @deal_record.update_attribute(:first_sell,true)
    end
    redirect_to deal_records_path(get_switch_params)
  end

  # 设置为转出至冷钱包
  def switch_to_trezor
    switch_real_profit_from 0
    redirect_to deal_records_path(get_switch_params)
  end

  # 交易列表能按照数量显示消账记录并能转回到未卖记录
  def switch_to_balance
    switch_real_profit_from 0.01
    redirect_to deal_records_path(get_switch_params)
  end

  def auto_send_trezor_count
    count = 0
    if $send_to_trezor_amount > 0
      make_trezor_count_records.each do |dr|
        dr.update_attributes(real_profit: 0, auto_sell: 1)
        count += 1
      end
    end
    put_notice "已将#{count}笔资料转入冷钱包"
    go_deal_records
  end

  def auto_send_balance_count
    count = 0
    make_balance_count_records.each do |dr|
      dr.update_attributes(real_profit: 0.01, auto_sell: 1)
      count += 1
    end
    put_notice "已将#{count}笔资料转入消帐记录"
    go_deal_records
  end

  private

    def set_deal_record
      @deal_record = DealRecord.find(params[:id])
    end

    def deal_record_params
      params.require(:deal_record).permit(:account, :data_id, :symbol, :deal_type, :price, :amount, :fees, :purpose, :loss_limit, :earn_limit, :auto_sell, :order_id, :real_profit, :first_sell)
    end

    def make_trezor_count_records
      DealRecord.make_count_records($send_to_trezor_amount)
    end

    def make_balance_count_records
      DealRecord.make_count_records(DealRecord.unsell_amount - DealRecord.btc_amount)
    end

    def switch_real_profit_from( value )
      if @deal_record.auto_sell and @deal_record.real_profit == value
        @deal_record.update_attributes(auto_sell: false, real_profit: nil)
      else
        @deal_record.update_attributes(auto_sell: true, real_profit: value)
      end
    end

    def get_switch_params
      {
        show_all: params[:show_all],
        show_unsell: params[:show_unsell],
        show_balance: params[:show_balance],
        order_field: params[:order_field]
      }
    end

    # 为卖出下单准备参数
    def setup_sell_params
      set_invest_params(20,'1')
      set_invest_params(0,swap_sec)
    end

    # 为买入下单准备参数
    def setup_buy_params
      set_invest_params(30,'1')
      set_invest_params(0,swap_sec)
    end

end
