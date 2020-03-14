class PropertiesController < ApplicationController

  before_action :set_property, only: [:edit, :update, :update_amount, :destroy, :delete]
  after_action :update_all_portfolio_attributes, only: [:create, :destroy]

  # 资产负债列表
  def index
    tags = params[:tags]
    extags = params[:extags]
    if tags
      if mode = params[:mode] and !mode.empty?
        @properties = get_properties_from_tags(tags,extags,mode)
      elsif tags  # 由tag_cloud来的单一标签
        @properties = Property.tagged_with(tags.strip)
      end
      # 计算资产总值以供显示占比使用
      @properties_sum = 0
      @properties.each {|p| @properties_sum += p.amount_to}
    else
      @properties = Property.all_sort admin?
    end
  end

  # 显示火币短线资产
  def huobi_assets
    redirect_to action: :index, tags: '170'
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
    if (@property and @property.hidden? and !admin?) or !@property # 非管理员无法编辑隐藏资产
      put_warning t(:property_non_exist)
      go_properties
    end
  end

  # 储存更新资产
  def update
    params[:property][:amount].gsub!(',','')
    if @property.update_attributes(property_params)
      put_notice t(:property_updated_ok) + add_id(@property) + add_amount(@property)
      session[:path] ? go_back : go_properties
    else
      render action: :edit
    end
  end

  # 从列表中快速更新资产金额
  def update_amount
    update_property_amount
  end

  # 删除资产
  def destroy
    @property.destroy
    put_notice t(:property_destroy_ok)
    go_properties
  end

  # 删除资产
  def delete
    destroy
  end

  private

    # 取出特定的某笔数据
    def set_property
      begin
        @property = Property.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        @property = nil
      end
    end

    # 设定栏位安全白名单
    def property_params
      if admin?
        params[:property][:tag_list].gsub!(' ',',') if !params[:property][:tag_list].nil?
        params.require(:property).permit(:name,:amount,:currency_id,:is_hidden,:is_locked,:tag_list)
      else
        params.require(:property).permit(:name,:amount,:currency_id)
      end
    end

end
