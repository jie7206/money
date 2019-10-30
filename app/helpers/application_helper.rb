module ApplicationHelper

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

  # 默认的金额显示格式
  def to_n( number, pos=2 )
    number > 0 ? format("%.#{pos}f",number.floor(pos)) : format("%.#{pos}f",number.ceil(pos))
  end

  # 默认的时间显示格式
  def to_t( time )
    time.to_s(:db)
  end

  # 点击后立刻选取所有文字
  def select_all
    'this.select()'
  end

  # 建立返回列表的链接
  def link_back_to_properties
    raw "#{link_to t(:property_index), properties_path}"
  end

  # 建立返回列表的链接
  def link_back_to_currencies
    raw "#{link_to t(:currency_index), currencies_path}"
  end

  # 建立返回列表的链接
  def link_back_to_interests
    raw "#{link_to t(:interest_index), interests_path}"
  end

  # 移动鼠标能改变表格列的背景颜色
  def change_row_color( rgb='#FFCF00' )
    raw "onMouseOver=\"this.style.background='#{rgb}'\"  onMouseOut=\"this.style.background='#FFFFFF'\""
  end

  # 链接到编辑类别
  def link_edit_to( instance, link_text = nil )
    link_text ||= instance.name
    eval "link_to '#{link_text}', edit_#{instance.class.to_s.downcase}_path(instance)"
  end

end
