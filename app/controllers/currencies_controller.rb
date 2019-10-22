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
        format.html { redirect_to currencies_url, notice: t(:currency_created_ok) }
      else
        format.html { render :new }
      end
    end
  end

  # 更新货币
  def update
    respond_to do |format|
      if @currency.update(currency_params)
        format.html { redirect_to currencies_url, notice: t(:currency_updated_ok) }
      else
        format.html { render :edit }
      end
    end
  end

  # 删除货币
  def destroy
    @currency.destroy
    respond_to do |format|
      format.html { redirect_to currencies_url, notice: t(:currency_destroied_ok) }
    end
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

end
