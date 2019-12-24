class DealRecordsController < ApplicationController

  before_action :check_admin
  before_action :set_deal_record, only: [:edit, :update, :destroy, :delete]

  def index
    if params[:show_all]
      @deal_records = DealRecord.order('created_at desc')
    elsif params[:show_sell]
      @deal_records = DealRecord.where('auto_sell = 1').order('created_at desc')
    else
      @deal_records = DealRecord.where('auto_sell = 0').order('created_at desc')
    end
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

  private

    def set_deal_record
      @deal_record = DealRecord.find(params[:id])
    end

    def deal_record_params
      params.require(:deal_record).permit(:account, :data_id, :symbol, :deal_type, :price, :amount, :fees, :purpose, :loss_limit, :earn_limit, :auto_sell, :order_id, :real_profit)
    end

end
