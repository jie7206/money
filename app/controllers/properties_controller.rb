class PropertiesController < ApplicationController

  before_action :set_property, only: [:edit, :update, :update_amount, :destroy]

  # 资产负债列表
  def index
    @properties = Property.all_sort admin?
    get_statistical_data # 获取资产的净值等统计数据
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
    if @property.hidden? and !admin? # 非管理员无法编辑隐藏资产
      put_warning t(:property_non_exist)
      go_properties
    end
  end

  # 储存更新资产
  def update
    if @property.update_attributes(property_params)
      put_notice t(:property_updated_ok)
      go_properties
    else
      render action: :edit
    end
  end

  # 从列表中快速更新资产金额
  def update_amount
    if new_amount = params["new_amount_#{params[:id]}"]
      @property.update_attribute(:amount, new_amount)
      put_notice t(:property_updated_ok)
    end
    go_properties
  end

  # 删除资产
  def destroy
    if @property.destroy
      put_notice t(:property_destroy_ok)
      go_properties
    end
  end

  private

    # 取出特定的某笔数据
    def set_property
      @property = Property.find(params[:id])
    end

    # 设定栏位安全白名单
    def property_params
      params.require(:property).permit(:name,:amount,:currency_id,:is_hidden)
    end

    # 获取资产的净值等统计数据
    def get_statistical_data
      @properties_net_value_twd = Property.net_value :twd, admin_hash?
      @properties_net_value_cny = Property.net_value :cny, admin_hash?
      @properties_lixi_twd = Property.lixi :twd, admin_hash?
      @properties_value_twd = Property.value :twd, admin_hash?(only_positive: true)
      @properties_loan_twd = Property.value :twd, admin_hash?(only_negative: true)
    end

end
