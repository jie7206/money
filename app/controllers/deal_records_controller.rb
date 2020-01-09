class DealRecordsController < ApplicationController

  # before_action :check_admin
  before_action :set_deal_record, only: [:edit, :update, :destroy, :delete]

  def index
    if params[:show_all]
      @deal_records = DealRecord.order('created_at desc')
    elsif params[:show_sell]
      @deal_records = DealRecord.where('auto_sell = 1').order('created_at desc')
    else
      update_btc_price
      @auto_refresh_sec = $auto_refresh_sec_for_deal_records
      @deal_records = DealRecord.where('auto_sell = 0').order('created_at desc')
    end
    summary
    @get_max_sell_count = get_max_sell_count
    @first_deal_record_profit = DealRecord.first_profit
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
    if File.exist? $auto_invest_log_path
        File.delete $auto_invest_log_path
        File.new $auto_invest_log_path, 'w+'
        put_notice t(:delete_invest_log_ok)
    end
    go_back
  end

  # 清空交易记录
  def clear
    n = DealRecord.where(auto_sell:0).delete_all
    put_notice t(:clear_deal_records_ok) + "(#{n}#{t(:bi)})"
    go_deal_records
  end

  # 压缩卖出记录将所有的卖出记录累计成一笔
  def zip_sell_records
    price = amount = real_profit = 0
    rs = DealRecord.where(auto_sell:1).order('created_at')
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

  # 定投秒数尾数是0则回传1反之亦然
  def swap_sec
    sec = get_invest_params(0)
    return sec[-1] == '0' ? sec[0..-2]+'1' : sec[0..-2]+'0'
  end

  # 执行卖出下单以弥补自动交易买入后延迟卖出的不足
  def send_sell_deal_records
    below_price = get_invest_params(1).to_f
    profit = get_invest_params(12).to_f
    if DealRecord.profit_cny > profit and DealRecord.first.price_now > below_price
      set_invest_params(0,swap_sec)
      put_notice t(:send_sell_deal_records_ok)
      sleep 20
      redirect_to invest_log_path
    else
      put_notice t(:send_sell_deal_records_error)
      go_deal_records
    end

  end

  # 交易列表新增执行停损功能
  def send_stop_loss
    set_invest_params(19,'1')
    set_invest_params(0,swap_sec)
    put_notice t(:send_stop_loss_ok)
    sleep 20
    redirect_to invest_log_path
  end

  private

    def set_deal_record
      @deal_record = DealRecord.find(params[:id])
    end

    def deal_record_params
      params.require(:deal_record).permit(:account, :data_id, :symbol, :deal_type, :price, :amount, :fees, :purpose, :loss_limit, :earn_limit, :auto_sell, :order_id, :real_profit)
    end

end
