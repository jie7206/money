class CurrenciesController < ApplicationController

  before_action :set_currency, only: [:edit, :update, :destroy, :delete]

  # 货币列表
  def index
    @currencies = Currency.all
  end

  # 新建货币表单
  def new
    @currency = Currency.new
  end

  # 编辑货币表单
  def edit
  end

  # 新建货币
  def create
    @currency = Currency.new(currency_params)
    if @currency.save
      put_notice t(:currency_created_ok)
      go_currencies
    else
      render :new
    end
  end

  # 更新货币
  def update
    if @currency.update(currency_params)
      put_notice t(:currency_updated_ok)
      go_currencies
    else
      render :edit
    end
  end

  # 删除货币
  def destroy
    @currency.destroy
    put_notice t(:currency_destroyed_ok)
    go_currencies
  end

  # 删除货币
  def delete
    destroy
  end

  private

    # 取出特定的某笔数据
    def set_currency
      @currency = Currency.find(params[:id])
    end

    # 设定栏位安全白名单
    def currency_params
      if admin?
        params.require(:currency).permit(:name, :code, :symbol, :exchange_rate)
      else
        params.require(:currency).permit(:name, :code, :exchange_rate)
      end
    end

end
