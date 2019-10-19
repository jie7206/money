module ApplicationHelper

  # 网站标题
  def site_name
    $site_name
  end

  # 网站Logo图示
  def site_logo
    raw('<span id="site_logo">'+
      image_tag("rails.png", alt: site_name, align: "absmiddle")+'</span>')
  end

  # 判断是否已登入
  def login?
    session[:login] == true
  end

end
