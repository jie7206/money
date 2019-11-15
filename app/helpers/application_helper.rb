module ApplicationHelper

  include ActsAsTaggableOn::TagsHelper

  # 为哪些模型自动建立返回列表的链接以及执行返回列表的指令
  $models = %w(property currency interest item portfolio record)
  # 为哪些类型的通知自动产生方法
  $flashs = %w(notice warning)
  # 建立从列表中快速更新某个值的方法
  $quick_update_attrs = ["property:amount","item:price,amount"]
  # 资产组合的模式属性
  $modes = %w(none matchall any)
  # 记录数值的模型名称
  $record_classes = ($models - %w(record)).map{|w| w.capitalize} + ['NetValue','NetValueAdmin']

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

  # 链接到编辑类别
  def link_edit_to_image( instance, image_name = 'doc.png', back_path = nil )
    path_str = ", path: '#{back_path}'" if !back_path.nil?
    eval "link_to image_tag('#{image_name}'), {controller: :#{instance.class.to_s.downcase.pluralize}, action: :edit, id: #{instance.id}#{path_str}}, {id:'#{instance.class.name.downcase}_edit_#{instance.id}'}"
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

  # 资产组合新增模式属性以便能支持所有法币资产的查看
  def select_record_model( obj )
    eval("obj.select :class_name, $record_classes.collect {|m| [m, m]}")
  end

  # 更新汇率的链接
  def update_all_exchange_rates_link
    link_to t(:update_all_exchange_rates), {controller: :currencies, action: :update_all_exchange_rates, path: request.fullpath}, {id:'update_all_exchange_rates'}
  end

  # 更新全部的链接
  def update_all_data_link
    link_to t(:update_all_data), {controller: :properties, action: :update_all_data, path: request.fullpath}, {id:'update_all_data'}
  end

  # 更新火币的链接
  def update_huobi_assets_link
    link_to t(:update_huobi_assets), {controller: :main, action: :update_huobi_assets, path: request.fullpath}, { id: 'update_huobi_assets' }
  end

  # 更新资产组合的链接
  def update_all_portfolios_link
    link_to t(:update_all_portfolios), {controller: :portfolios, action: :update_all_portfolios, path: request.fullpath}, {id:'update_all_portfolios'}
  end

  # 更新房价的链接
  def update_house_price_link
    link_to t(:update_house_price), {controller: :items, action: :update_house_price, path: request.fullpath}, {id:'update_house_price'}
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
    raw(link_to(portfolio.name,
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

  # 显示数据创建及更新时间
  def timestamps( obj )
    if !obj.new_record?
      raw("<div class='timestamps'>
        #{t(:created_at)}: #{obj.created_at.to_s(:db)}
        #{t(:updated_at)}: #{obj.updated_at.to_s(:db)}
      </div>")
    end
  end

  # 显示删除某笔数据链接
  def link_to_delete( obj )
    if !obj.new_record?
      name = obj.class.name.downcase
      raw(' | '+eval("link_to t(:delete_#{name}), delete_#{name}_path(@#{name}), id: 'delete_#{name}'"))
    end
  end

  # 显示资产统计讯息
  def show_summary_tr( colspan )
   raw "<tr>
          <td colspan='#{colspan}' class='thead'>
            #{render 'shared/summary'}
          </td>
        </tr>"
  end
  # 建立返回列表的链接
  $models.each do |n|
    define_method "link_back_to_#{n.pluralize}" do
      eval("raw(\"" + '#{' + "link_to t(:#{n}_index), #{n.pluralize}_path" + "}\")")
    end
  end

  # Fusioncharts属性大全: http://wenku.baidu.com/link?url=JUwX7IJwCbYMnaagerDtahulirJSr5ASDToWeehAqjQPfmRqFmm8wb5qeaS6BsS7w2_hb6rCPmeig2DBl8wzwb2cD1O0TCMfCpwalnoEDWa
  def show_fusion_chart
    raw "<div id=\"chartContainer\"></div><p>
    <script type=\"text/javascript\">
    FusionCharts.ready(function () {
        var myChart = new FusionCharts({
          \"type\": \"line\",
          \"renderAt\": \"chartContainer\",
          \"width\": \"95%\",
          \"height\": \"450\",
          \"dataFormat\": \"xml\",
          \"dataSource\": \"<chart yAxisMinValue='#{@bottom_value}' yAxisMaxvalue='#{@top_value}' animation='0' caption='#{@caption}' xaxisname='　' yaxisname='' formatNumberScale='0' formatNumber ='0' palettecolors='#CC0000' bgColor='#F0E68C' canvasBgColor='#F0E68C' valuefontcolor='#000000' showValues='0' borderalpha='0' canvasborderalpha='0' theme='fint' useplotgradientcolor='0' plotborderalpha='0' placevaluesinside='0' rotatevalues='1'  captionpadding='12' showaxislines='0' axislinealpha='0' divlinealpha='0' lineThickness='3' drawAnchors='0'>#{@chart_data}</chart>\"
        });
      myChart.render();
    });
    </script>"
  end

  # 建立查看走势图链接
  def chart_link( obj )
    raw(link_to(image_tag('chart.png',width:16),{controller: obj.class.name.pluralize.downcase.to_sym, action: :chart, id: obj.id},{target: :blank}))
  end

end
