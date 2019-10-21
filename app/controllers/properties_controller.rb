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
      go_properties
    else
      render :new
    end
  end

  def edit
    get_property_by_id
  end

  def update
    get_property_by_id
    if @property.update_attributes(property_params)
      flash[:notice] = "资产已更新成功！"
      go_properties
    else
      render action: :edit
    end
  end

  def destroy
    get_property_by_id
    if @property.destroy
      flash[:notice] = "资产删除成功！"
      go_properties
    end
  end

  private

    # 读取特定资产
    def get_property_by_id
      @property = Property.find(params[:id])
    end

    # 供安全更新使用
    def property_params
      params.require(:property).permit(:name,:amount)
    end

end
