class DealRecordsController < ApplicationController

  before_action :check_admin
  before_action :set_deal_record, only: [:edit, :update, :destroy, :delete]

  def index
    @deal_records = DealRecord.order('created_at desc') #.limit($deal_records_limit)
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

  def destroy
    @deal_record.destroy
    put_notice t(:deal_record_destroyed_ok)
    go_deal_records
  end

  def delete
    destroy
  end

  # 清空交易记录
  def clear
    DealRecord.delete_all
    put_notice t(:clear_deal_records_ok)
    go_deal_records
  end

  private

    def set_deal_record
      @deal_record = DealRecord.find(params[:id])
    end

    def deal_record_params
      params.require(:deal_record).permit(:account, :data_id, :symbol, :deal_type, :price, :amount, :fees, :purpose, :loss_limit, :earn_limit, :auto_sell, :order_id)
    end

end
