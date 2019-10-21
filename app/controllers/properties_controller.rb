class PropertiesController < ApplicationController

  # 资产负债列表
  def index
    @properties = Property.all
  end

  # 新建资产表单
  def new
    @property = Property.new
  end

  # 储存新建资产
  def create
    @property = Property.new(property_params)
    if @property.save
      put_notice t(:property_created_ok)
      go_properties
    else
      render :new
    end
  end

  # 编辑资产表单
  def edit
    get_property_by_id
  end

  # 储存更新资产
  def update
    get_property_by_id
    if @property.update_attributes(property_params)
      put_notice t(:property_updated_ok)
      go_properties
    else
      render action: :edit
    end
  end

  # 删除资产
  def destroy
    get_property_by_id
    if @property.destroy
      put_notice t(:property_destroy_ok)
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
