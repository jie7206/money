class CurrenciesController < ApplicationController

  before_action :set_currency, only: [:edit, :update, :destroy]

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
    put_notice t(:currency_destroied_ok)
    go_currencies
  end

  # 更新所有货币的汇率值
  def update_all_exchange_rates
    if count = update_digital_exchange_rates and count > 0 then
      put_notice "#{count} #{t(:n_digital_exchange_rates_updated_ok)}" end
    if count = update_legal_exchange_rates and count > 0 then
      put_notice "#{count} #{t(:n_legal_exchange_rates_updated_ok)}" end
    go_currencies
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
