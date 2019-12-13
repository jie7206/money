class OpenOrdersController < ApplicationController

  before_action :set_open_order, only: [:destroy, :delete]

  def index
    @open_orders = OpenOrder.all
  end

  def check_open_order
    put_notice `python py/open_orders.py`
    go_open_orders
  end

  def destroy
    @open_order.destroy
    put_notice t(:destroy_open_order_ok)
    go_open_orders
  end

  def delete
    root = JSON.parse(`python py/cancel_order.py order_id=#{@open_order.order_id}`)
    if root["status"] == "ok"
      put_notice t(:delete_open_order_ok)
      dr.clear_order if dr = DealRecord.find_by_order_id(@open_order.order_id)
    else
      put_notice t(:delete_open_order_error)
    end
    destroy
  end

  # 清空下单记录
  def clear
    root = JSON.parse(`python py/clear_orders.py symbol=btcusdt`)
    if root["status"] == "ok"
      OpenOrder.delete_all
      put_notice t(:clear_open_orders_ok)+t(:delete_open_order_ok)+"(#{root["data"]["success-count"]}#{t(:bi)})"
    else
      put_notice t(:delete_open_order_error)
    end
    go_open_orders
  end

  private

    def set_open_order
      @open_order = OpenOrder.find(params[:id])
    end

end
