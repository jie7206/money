module ApplicationHelper

  include ActsAsTaggableOn::TagsHelper

  # 为哪些模型自动建立返回列表的链接以及执行返回列表的指令 eq. link_back_to_xxx, go_xxx
  $models = %w(property currency interest item portfolio record deal_record open_order)
  # 为哪些类型的通知自动产生方法
  $flashs = %w(notice warning)
  # 建立从列表中快速更新某个值的方法
  $quick_update_attrs = ["property:amount","item:price,amount"]
  # 资产组合的模式属性
  $modes = %w(none matchall any)
  # 记录数值的模型名称
  $record_classes = \
    %w(property currency interest item portfolio).\
    map{|w| w.capitalize} + ['NetValue','NetValueAdmin']

  # 建立返回列表的链接
  $models.each do |n|
    define_method "link_back_to_#{n.pluralize}" do
      eval("raw(\"" + '#{' + "link_to t(:#{n}_index), #{n.pluralize}_path" + "}\")")
    end
  end

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
  def to_n( number, pos=2, opt={} )
    if number and number.class == String
      if number.strip!
        number.sub!("<_io.TextIOWrapper name='<stdout>' mode='w' encoding='UTF-8'>",'')
      end
    end
    if number.class != Array and number = number.to_f
      if opt[:round]
        return format("%.#{pos}f",number)
      else
        return number > 0 ? format("%.#{pos}f",number.floor(pos)) : format("%.#{pos}f",number.ceil(pos))
      end
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
  def to_t( time, simple = false )
    if !simple
      time.to_s(:db)
    else
      time.strftime("%y%m%d-%H%M%S")
    end
  end

  # 默认的时间显示格式
  def to_time( time )
    time.strftime("%Y-%m-%d %H:%M:%S")
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
  def link_edit_to( instance, link_text = instance.name, back_path = nil, options = {} )
    path_str = ", path: '#{back_path}'" if !back_path.nil?
    eval "link_to '#{link_text}', {controller: :#{instance.class.table_name}, action: :edit, id: #{instance.id}#{path_str}}, #{options}"
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

  # 选择交易记录的分类
  def select_record_model( obj )
    eval("obj.select :class_name, $record_classes.collect {|m| [m, m]}")
  end

  # 选择交易记录的账号
  def select_deal_record_account( obj )
    eval("obj.select :account, ['135','170'].collect {|a| [a, a]}")
  end

  # 选择交易记录的账号
  def select_huobi_account( account = '170' )
    select_tag "account", options_for_select([ "135", "170" ], account)
  end

  # 选择交易的类型
  def select_order_type( deal_type )
    select_tag "deal_type", options_for_select([ ["限价买", "buy-limit"], ["市价买", "buy-market"], ["限价卖", "sell-limit"], ["市价卖", "sell-market"] ], deal_type)
  end

  # 选择交易记录的类型
  def select_deal_record_type( obj )
    eval("obj.select :deal_type, ['buy','sell'].collect {|m| [m.upcase, m]}")
  end

  # 更新所有汇率的链接
  def update_all_exchange_rates_link
    link_to t(:update_all_exchange_rates), {controller: :currencies, action: :update_all_exchange_rates, path: request.fullpath}, {id:'update_all_exchange_rates'}
  end

  # 更新法币汇率的链接
  def update_all_legal_exchange_rates_link
    link_to t(:update_all_legal_exchange_rates), {controller: :currencies, action: :update_all_legal_exchange_rates, path: request.fullpath}, {id:'update_all_legal_exchange_rates'}
  end

  # 更新所有数字货币汇率的链接
  def update_all_digital_exchange_rates_link
    link_to t(:update_all_digital_exchange_rates), {controller: :currencies, action: :update_all_digital_exchange_rates, path: request.fullpath}, {id:'update_all_digital_exchange_rates'}
  end

  # 更新比特币汇率的链接
  def update_btc_exchange_rates_link
    link_to t(:update_btc_exchange_rates), {controller: :currencies, action: :update_btc_exchange_rates, path: request.fullpath}, {id:'update_btc_exchange_rates'}
  end

  # 更新全部的链接
  def update_all_data_link
    link_to t(:update_all_data), {controller: :properties, action: :update_all_data, path: request.fullpath}, {id:'update_all_data'}
  end

  # 更新比特币的链接
  def update_btc_link
    link_to t(:update_btc), {controller: :currencies, action: :update_btc_exchange_rates, path: request.fullpath}, {id:'update_btc_exchange_rates'}
  end

  # 更新火币的链接
  def update_huobi_data_link
    link_to t(:update_huobi_data), {controller: :main, action: :update_huobi_data, path: request.fullpath}, { id: 'update_huobi_data' }
  end

  # 更新火币的链接
  def update_huobi_assets_link
    link_to t(:update_huobi_assets), {controller: :main, action: :update_huobi_assets, path: request.fullpath}, { id: 'update_huobi_assets' }
  end

  # 更新火币的链接
  def update_huobi_records_link
    link_to t(:update_huobi_records), {controller: :main, action: :update_huobi_records, path: request.fullpath}, { id: 'update_huobi_records' }
  end

  # 更新资产组合的链接
  def update_all_portfolios_link
    link_to t(:update_all_portfolios), {controller: :portfolios, action: :update_all_portfolios, path: request.fullpath}, {id:'update_all_portfolios'}
  end

  # 更新房价的链接
  def update_house_price_link
    link_to t(:update_house_price), {controller: :items, action: :update_house_price, path: request.fullpath}, {id:'update_house_price'}
  end

  # 下单列表链接
  def order_list_link
    link_to t(:order_list), {controller: :open_orders}, {id:'open_orders'}
  end

  # 下单列表链接
  def check_open_orders_link
    link_to t(:check_open_orders), {controller: :open_orders, action: :check_open_order}, {id:'check_open_orders'}
  end

  # K线图链接
  def kline_chart_link( text )
    link_to text, {controller: :main, action: :kline_chart}, {target: :blank}
  end

  # K线图链接
  def line_chart_link( currency, opt={} )
    if !currency.symbol_code.empty?
      text = opt[:show] == 'name' ? currency.name : currency.symbol_code
      return raw(link_to text, {controller: :main, action: :line_chart, symbol: currency.symbol_code.downcase}, {target: :blank})
    elsif opt[:name]
      return currency.name
    else
      return ''
    end
  end

  # 定投记录链接
  def invest_log_link
    link_to t(:invest_log), invest_log_path
  end

  # 清空定投记录链接
  def clear_invest_log_link
    link_to t(:clear_invest_log), delete_invest_log_path(path: request.fullpath)
  end

  # 撤消全部下单并清空记录链接
  def clear_open_orders_link
    link_to t(:clear_open_orders), clear_open_orders_path, { id: 'clear_open_orders' }
  end

  # 设置定投参数表单链接
  def set_auto_invest_form_link
    link_to t(:set_auto_invest_params), set_auto_invest_form_path, { id: 'set_auto_invest_form' }
  end

  # 更新系统参数表单链接
  def system_params_form_link
    link_to t(:update_system_params), system_params_form_path, { id: 'system_params_form' }
  end

  # 火币测试链接
  def test_huobi_link
    link_to t(:test_huobi), '/test_huobi.json', { id: 'test_huobi' }
  end

  # 与资产更新相关的链接
  def update_btc_huobi_portfolios_link
    raw(' | ' + update_btc_exchange_rates_link + \
    ' | ' + update_huobi_assets_link + \
    ' | ' + update_all_portfolios_link)
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
      name = obj.class.table_name.singularize
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

  # 显示资产净值链接
  def show_net_value_link
    raw "<span id=\"properties_net_value_twd\">#{link_to(@properties_net_value_twd.to_i, chart_path, target: :blank, title: @properties_net_growth_ave_month.to_i.to_s+'/月 '+t(:twd))}</span> (<span id=\"properties_net_value_cny\" title=\"#{t(:cny)}\">#{@properties_net_value_cny.to_i}</span>)"
  end

  # Fusioncharts属性大全: http://wenku.baidu.com/link?url=JUwX7IJwCbYMnaagerDtahulirJSr5ASDToWeehAqjQPfmRqFmm8wb5qeaS6BsS7w2_hb6rCPmeig2DBl8wzwb2cD1O0TCMfCpwalnoEDWa
  def show_fusion_chart
    raw "<div id=\"chartContainer\"></div><p>
    <script type=\"text/javascript\">
    FusionCharts.ready(function () {
        var myChart = new FusionCharts({
          \"type\": \"line\",
          \"renderAt\": \"chartContainer\",
          \"width\": \"100%\",
          \"height\": \"450\",
          \"dataFormat\": \"xml\",
          \"dataSource\": \"<chart yAxisMinValue='#{@bottom_value}' yAxisMaxvalue='#{@top_value}' animation='0' caption='#{@caption}' xaxisname='　' yaxisname='' formatNumberScale='0' formatNumber ='0' palettecolors='#CC0000' bgColor='#F0E68C' canvasBgColor='#F0E68C' valuefontcolor='#000000' showValues='0' borderalpha='0' canvasborderalpha='0' theme='fint' useplotgradientcolor='0' plotborderalpha='0' placevaluesinside='0' rotatevalues='1'  captionpadding='5' showaxislines='0' axislinealpha='0' divlinealpha='0' lineThickness='3' drawAnchors='1'>#{@chart_data}</chart>\"
        });
      myChart.render();
    });
    </script>"
  end

  # 建立查看走势图链接
  def chart_link( obj )
    raw(link_to(image_tag('chart.png',width:16),{controller: obj.class.name.pluralize.downcase.to_sym, action: :chart, id: obj.id},{target: :blank}))
  end

  # 显示火币时间讯息使用
  def get_timestamp
    timestamp = `python py/timestamp.py`
    puts "timestamp = #{timestamp}"
    return timestamp.to_i
  end

  # 将UTC time in millisecond显示成一般日期格式
  def show_time( utc_time )
    if timestamp = get_timestamp and timestamp > 0
      (Time.now-(get_timestamp-utc_time.to_i/1000).second).strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  # 是否显示打勾的图示
  def show_ok( boolean )
    image_tag('ok.png',width:15) if boolean
  end

  # 显示交易类别
  def show_deal_type( type )
    type.index('buy') ? '买进' : '卖出'
  end

  # 显示较长的文字数据
  def show_long_text( string, length = 10 )
    raw "<span title='#{string}'>#{truncate(string,length: length)}</span>"
  end

  # 显示附加文字的内容
  def add_title( text, title )
    raw "<span title='#{title}'>#{text}</span>"
  end

  # 显示投资目的字符串
  def show_purpose( purpose )
    ": #{purpose}" if purpose and !purpose.empty?
  end

  # 显示绿色或红色背景
  def if_red_bg( value, compare )
    raw('class="red_bg"') if compare.to_f > 0 and value.to_f > compare.to_f
  end

  # 显示绿色或红色背景
  def if_green_bg( value, compare )
    raw('class="green_bg"') if compare.to_f > 0 and value.to_f < compare.to_f
  end

  # 显示火币下单链接(显示价格,个别数据具柄,earn_or_loss)
  def huobi_order_link( price, dr, el, link = true )
    if link
    link_to(add_title(price,"¥#{eval("dr.#{el}_limit")}#{show_purpose(dr.purpose)}"), controller: :main, action: :place_order_form, id: dr.id, type: el) if price.to_f > 0
    else
      add_title(price,"¥#{eval("dr.#{el}_limit")}#{show_purpose(dr.purpose)}")
    end
  end

  # 火币下单链接
  def order_link( amount = nil )
    link_to t(:huobi_order), controller: :main, action: :place_order_form, amount: amount
  end

  # 建立查看火币下单链接
  def look_order_link( dr, len = 11 )
    link_to(dr.order_id[-11+(11-len)..-1], {controller: :main, action: :look_order, account: dr.account, id: dr.order_id},{target: :blank}) if dr.order_id and !dr.order_id.empty?
  end

  def symbol_title(symbol)
    s = symbol.upcase.sub("USDT","/USDT").sub("HUSD","/HUSD")
    s = s[1..-1] if s[0] == "/"
    return s
  end

  def period_title(period)
    period.sub("min","分钟").sub("hour","小时").sub("day","天").sub("week","周").sub("mon","月").sub("year","年")
  end

  # 取得最新的比特币报价
  def btc_price
    begin
      root = JSON.parse(`python py/huobi_price.py symbol=btcusdt period=1min size=1`)
      if root["data"] and root["data"][0]
        return format("%.2f",root["data"][0]["close"]).to_f
      else
        return btc_price_local
      end
    rescue
      return btc_price_local
    end
  end

  def btc_price_local
    Currency.find_by_code('BTC').to_usd.floor(2)
  end

  # 显示切换分钟链接
  def period_link_for_chart(action)
    result = ""
    result += "<span class='sub_text'>#{link_to t(:currency_index), controller: :currencies}</span>"
    %w[1min 5min 15min 30min 60min 4hour 1day 1week 1mon].each do |period|
    result += "<span class='sub_text'>#{link_to period_title(period), action: action, symbol: params[:symbol], period: period}</span>"
    end
    swap_action = action == :kline_chart ? :line_chart : :kline_chart
    swap_label = swap_action == :kline_chart ? t(:see_kline) : t(:see_line)
    result += "<span class='sub_text'>#{link_to swap_label, action: swap_action, symbol: params[:symbol], period: params[:period]}</span>"
    return raw(result)
  end

  # 获取未卖出的交易笔数
  def get_unsell_deal_records_count
    DealRecord.unsell_count
  end

  # 获取定投参数的值
  def get_invest_params( index )
    File.read($auto_invest_params_path).split(' ')[index]
  end

  # 显示定投参数的设定值链接
  def invest_params_setup_link( index, min, max, step, pos = 0, pass_value = nil )
    result = ''
    (min..max).step(step).each do |n|
      value = to_n(n.floor(pos),pos)
      style = value == get_invest_params(index) ? 'invest_param_select' : ''
      if value != pass_value
        result += link_to(value, setup_invest_param_path(i:index,v:value), class: style) + ' '
      end
    end
    return raw(result)
  end

end
