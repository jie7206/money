class TrialListsController < ApplicationController

    before_action :set_trial_list, only: [:edit, :update, :destroy, :delete]

    # 输入比特币每月增长利率以及每月生活费计算能维持多少年
    def index
      update_huobi_assets_core if $auto_update_huobi_assets > 0
      prepare_vars
    end

    def new
    end

    def edit
    end

    def create
    end

    def update
    end

    def destroy
    end

    def save_trials_to_db
      prepare_vars
      TrialList.delete_all
      cal_btc_capital
      (0..trial_records_number(true)).each do |n|
        this_date = Date.today.at_beginning_of_month+n.month
        month_sell = @month_cost/@usdt2cny/@btc_price
        trial_date = this_date
        begin_price = @btc_price.floor(2)
        begin_amount = to_n(@btc_amount,8).to_f
        if this_date > @month_cost_start
          month_cost = @month_cost.to_i
        else
          month_cost = 0
        end
        if this_date > @month_cost_start
          month_sell = to_n(month_sell,6).to_f
        else
          month_sell = 0
        end
        @btc_capital = @btc_capital - @month_cost
        begin_balance = @btc_capital
        begin_balance_twd = btc_capital_twd
        month_grow_rate = $trial_btc_month_grow_rate*100
        @btc_amount -= month_sell if this_date > @month_cost_start
        @btc_price = @btc_price.to_f * (1+$trial_btc_month_grow_rate)
        @btc_price = $trial_btc_max_price if @btc_price > $trial_btc_max_price
        @month_cost = (@month_cost.to_f * (1+$trial_cost_month_grow_rate)).to_i
        end_price = @btc_price.floor(2)
        end_balance = cal_btc_capital
        end_balance_twd = btc_capital_twd
        TrialList.create(
          trial_date: trial_date,
          begin_price: begin_price,
          begin_amount: begin_amount,
          month_cost: month_cost,
          month_sell: month_sell,
          begin_balance: begin_balance,
          begin_balance_twd: begin_balance_twd,
          month_grow_rate: month_grow_rate,
          end_price: end_price,
          end_balance: end_balance,
          end_balance_twd: end_balance_twd
        )
      end
      put_notice t(:save_trials_to_db_ok)
      redirect_to action: :index
    end

    private

      def prepare_vars
        @btc_price = get_btc_price
        @begin_price_for_trial = @btc_price
        @flow_assets_twd = Property.flow_assets_twd
        @btc_amount = get_btc_amount_from_system_params
        @btc_amount_now = Property.btc_amount_of_flow_assets
        @usdt_to_twd = usdt_to_twd
        @investable_fund_records_twd = Property.investable_fund_records_twd
        @investable_fund_records_cny = Property.investable_fund_records_cny
        if admin?
          @month_cost = $trial_life_month_cost_cny_admin
          @month_cost_start = $trial_month_cost_start_date_admin
        else
          @month_cost = $trial_life_month_cost_cny
          @month_cost_start = $trial_month_cost_start_date
        end
        @usdt2cny = $usdt_to_cny
        @cny2twd = DealRecord.new.cny_to_twd
      end

      def set_trial_list
        @trial_list = TrialList.find(params[:id])
      end

      def trial_list_params
        params.require(:trial_list).permit(:trial_date, :begin_price, :begin_amount, :month_cost, :month_sell, :begin_balance, :begin_balance_twd, :month_grow_rate, :end_price, :end_balance, :end_balance_twd)
      end

end
