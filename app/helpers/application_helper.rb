module ApplicationHelper

  # 网站标题
  def site_name
    $site_name
  end

  # 网站Logo图示
  def site_logo
    raw '<span id="site_logo">'+
      image_tag($site_logo, alt: site_name, align: "absmiddle")+'</span>'
  end

  # 判断是否已登入
  def login?
    session[:login] == true
  end

  # 默认的金额显示格式
  def to_n( number, pos=2 )
    number > 0 ? format("%.#{pos}f",number.floor(pos)) : format("%.#{pos}f",number.ceil(pos))
  end

  # 点击后立刻选取所有文字
  def select_all
    'this.select()'
  end

  # 建立返回资产列表的链接
  def link_back_to_properties
    raw "#{link_to t(:back_to_index), properties_path}"
  end

  # 移动鼠标能改变表格列的背景颜色
  def change_row_color( rgb='#FFCF00' )
    raw "onMouseOver=\"this.style.background='#{rgb}'\"  onMouseOut=\"this.style.background='#FFFFFF'\""
  end

  # 链接到编辑资产
  def link_edit_to(property)
    link_to property.name, edit_property_path(property)
  end

end
