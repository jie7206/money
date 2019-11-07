class PortfoliosController < ApplicationController

  before_action :check_admin
  before_action :set_portfolio, only: [:show, :edit, :update, :destroy]

  def index
    @portfolios = Portfolio.all.order(:order_num)
  end

  def show
  end

  def new
    @portfolio = Portfolio.new
    @portfolio.order_num = Portfolio.count+1
  end

  def edit
  end

  def create
    @portfolio = Portfolio.new(portfolio_params)
    if @portfolio.save
      put_notice t(:portfolio_created_ok)
      go_portfolios
    else
      render :new
    end
  end

  def update
    if @portfolio.update(portfolio_params)
      put_notice t(:portfolio_updated_ok)
      go_portfolios
    else
      render :edit
    end
  end

  def destroy
    @portfolio.destroy
    put_notice t(:portfolio_destroyed_ok)
    go_portfolios
  end

  def order_up
    Portfolio.order_up(params[:id])
    put_notice t(:portfolio_order_up_ok)
    go_portfolios
  end

  def order_down
    Portfolio.order_down(params[:id])
    put_notice t(:portfolio_order_down_ok)
    go_portfolios
  end

  private

    def set_portfolio
      @portfolio = Portfolio.find(params[:id])
    end

    def portfolio_params
      params.require(:portfolio).permit(:name, :include_tags, :exclude_tags, :order_num)
    end

end
