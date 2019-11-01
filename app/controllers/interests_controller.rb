class InterestsController < ApplicationController

  before_action :set_interest, only: [:show, :edit, :update, :destroy]

  def index
    @interests = Interest.all
    @interest_total_twd = Interest.total
    @interest_total_cny = Interest.total(:cny)
  end

  def show
  end

  def new
    @interest = Interest.new
  end

  def edit
  end

  def create
    @interest = Interest.new(interest_params)
    if @interest.save
      put_notice t(:interest_created_ok)
      go_interests
    else
      render :new
    end
  end

  def update
    if @interest.update(interest_params)
      put_notice t(:interest_updated_ok)
      go_interests
    else
      render :edit
    end
  end

  def destroy
    @interest.destroy
    put_notice t(:interest_destroyed_ok)
    go_interests
  end

  private

    def set_interest
      @interest = Interest.find(params[:id])
    end

    def interest_params
      params.require(:interest).permit(:property_id, :start_date, :rate)
    end

end
