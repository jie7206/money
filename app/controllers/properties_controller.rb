class PropertiesController < ApplicationController

  def index
    @properties = Property.all
  end

  def new
    @property = Property.new
  end

  def create
    @property = Property.new(property_params)
    if @property.save
      flash[:notice] = t(:property_created_ok)
      redirect_to action: :index
    else
      render :new
    end
  end

  def property_params
    params.require(:property).permit(:name,:amount)
  end

  def edit
  end

  def update
  end

  def destroy
  end

end
