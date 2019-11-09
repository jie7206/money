module ApplicationHelper

  include ActsAsTaggableOn::TagsHelper

  # 为哪些模型自动建立返回列表的链接以及执行返回列表的指令
  $models = %w(property currency interest item portfolio)
  # 为哪些类型的通知自动产生方法
  $flashs = %w(notice warning)
  # 建立从列表中快速更新某个值的方法
  $quick_update_attrs = ["property:amount","item:price,amount"]
  # 资产组合的模式属性
  $modes = %w(none matchall any)

  # 网站标题
  def site_name
    $site_name
  end

  # 网站Logo图示
  def site_logo
    raw image_tag($site_logo, id: "site_logo", alt: site_name, align: "absmiddle")
  end

  # 判断是否已登入
  def login?
    session[:login] == true
  end

  # 判断是否已登入
  def admin?
    session[:admin] == true
  end

  # 默认的数字显示格式
  def to_n( number, pos=2 )
    if number
      return number > 0 ? format("%.#{pos}f",number.floor(pos)) : format("%.#{pos}f",number.ceil(pos))
    else
      return format("%.#{pos}f",0)
    end
  end

  # 默认的金额显示格式
  def to_amount( number, is_digital = false )
    if is_digital
      return to_n( number, 8 )
    else
      return to_n( number, 2 )
    end
  end

  # 默认的时间显示格式
  def to_t( time )
    time.to_s(:db)
  end

  # 点击后立刻选取所有文字
  def select_all
    'this.select()'
  end

  # 移动鼠标能改变表格列的背景颜色
  def change_row_color( rgb='#FFCF00' )
    raw "onMouseOver=\"this.style.background='#{rgb}'\"  onMouseOut=\"this.style.background='#FFFFFF'\""
  end

  # 链接到编辑类别
  def link_edit_to( instance, link_text = nil, back_path = nil, options = {} )
    link_text ||= instance.name
    path_str = ", path: '#{back_path}'" if !back_path.nil?
    eval "link_to '#{link_text}', {controller: :#{instance.class.to_s.downcase.pluralize}, action: :edit, id: #{instance.id}#{path_str}}, #{options}"
  end

  # 用户在新建利息或商品时不能看到隐藏资产以供选择
  def select_property_id( obj )
    scope = admin? ? 'all' : 'all_visible'
    eval("obj.select :property_id, Property.#{scope}.collect { |p| [ p.name, p.id ] }")
  end

  # 资产组合新增模式属性以便能支持所有法币资产的查看
  def select_portfolio_mode( obj )
    eval("obj.select :mode, $modes.collect {|m| [m, m[0]]}")
  end

  # 更新汇率的链接
  def update_all_exchange_rates_link
    link_to t(:update_all_exchange_rates), {controller: :currencies, action: :update_all_exchange_rates, path: request.fullpath}, {id:'update_all_exchange_rates'}
  end

  # 更新资产组合的链接
  def update_all_portfolios_link
    link_to t(:update_all_portfolios), {controller: :portfolios, action: :update_all_portfolios, path: request.fullpath}, {id:'update_all_portfolios'}
  end

  # 资产标签云
  def get_tag_cloud
    @tags = Property.tag_counts_on(:tags)
  end

  # 建立排序上下箭头链接
  def link_up_and_down( id )
    raw(link_to('↑', action: :order_up, id: id)+' '+\
        link_to('↓', action: :order_down, id: id))
  end

  # 点击图标查看资产组合明细
  def look_portfolio_detail( portfolio )
    raw(link_to(image_tag('doc.png'),
      {controller: :properties, action: :index, portfolio_name: portfolio.name,
        tags: portfolio.include_tags, extags: portfolio.exclude_tags, mode: portfolio.mode, pid: portfolio.id},{id:"portfolio_#{portfolio.id}"}))
  end

  # 显示资产组合名称
  def portfolio_name
    text = ''
    if params[:portfolio_name]
      text = params[:portfolio_name]
    elsif params[:tags]
      text = params[:tags]
    end
    raw("<span class=\"sub_title\">(#{text})</span>") if !text.empty?
  end

  def item_url( obj )
    url = obj.url ? obj.url : ''
    if !url.empty? and url.index('http')
      return raw(link_to(t(:item_url),url,{target: :blank}))
    end
    return t(:item_url)
  end

  # 建立返回列表的链接
  $models.each do |n|
    define_method "link_back_to_#{n.pluralize}" do
      eval("raw(\"" + '#{' + "link_to t(:#{n}_index), #{n.pluralize}_path" + "}\")")
    end
  end

end
