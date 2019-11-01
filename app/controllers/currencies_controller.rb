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
    respond_to do |format|
      if @currency.save
        put_notice t(:currency_created_ok)
        format.html { redirect_to currencies_url }
      else
        format.html { render :new }
      end
    end
  end

  # 更新货币
  def update
    respond_to do |format|
      if @currency.update(currency_params)
        put_notice t(:currency_updated_ok)
        format.html { redirect_to currencies_url }
      else
        format.html { render :edit }
      end
    end
  end

  # 删除货币
  def destroy
    @currency.destroy
    respond_to do |format|
      put_notice t(:currency_destroied_ok)
      format.html { redirect_to currencies_url }
    end
  end

  # 更新所有货币的汇率值
  def update_all_exchange_rates
    if btc_price = get_btc_price and btc_price > 0
      update_btc_price(btc_price)
      put_notice "#{t(:update_btc_price_ok)} #{t(:latest_price)}: $#{btc_price}"
    end
    if count = update_legal_exchange_rates and count > 0
      put_notice "#{count} #{t(:n_legal_exchange_rates_updated_ok)}"
    end
    go_currencies
  end

  private

    # 取出特定的某笔数据
    def set_currency
      @currency = Currency.find(params[:id])
    end

    # 设定栏位安全白名单
    def currency_params
      params.require(:currency).permit(:name, :code, :exchange_rate)
    end

    # 更新比特币汇率
    def update_btc_price( btc_price )
      update_exchange_rate( 'BTC', (1/btc_price).floor(10) )
    end

end
