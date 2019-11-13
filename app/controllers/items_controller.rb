class ItemsController < ApplicationController

  before_action :set_item, only: [:edit, :update, :update_price, :update_amount, :destroy, :delete]
  after_action :update_all_portfolio_attributes, only: [:create, :update, :update_price, :update_amount, :destroy]

  def index
    @items = Item.all
  end

  def new
    @item = Item.new
  end

  def edit
    memory_back
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      put_notice t(:item_created_ok)
      go_items
    else
      render :new
    end
  end

  def update
    if @item.update(item_params)
      put_notice t(:item_updated_ok)
      session[:path] ? go_back : go_items
    else
      render :edit
    end
  end

  # 从列表中快速更新单价
  def update_price
    update_item_price
  end

  # 从列表中快速更新数量
  def update_amount
    update_item_amount
  end

  def destroy
    @item.destroy
    put_notice t(:item_destroyed_ok)
    go_items
  end

  def delete
    destroy
  end

  private

    def set_item
      @item = Item.find(params[:id])
    end

    def item_params
      params.require(:item).permit(:property_id, :price, :amount, :url)
    end

end
