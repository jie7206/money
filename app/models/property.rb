class Property < ApplicationRecord

  acts_as_taggable
  belongs_to :currency
  has_one :interest
  has_one :item

  after_create :update_records

  validates \
    :name,
      presence: {
        message: $property_name_blank_err },
      length: {
        maximum: $property_name_maxlength,
        message: $property_name_len_err }

  validates \
    :amount,
      presence: {
        message: $property_amount_blank_err } ,
      numericality: {
        message: $property_amount_nan_err }

  # 资产能以新台币或其他币种结算所有资产的总值
  def self.value( target_code = :twd, options = {} )
    result = 0
    all.each do |p|
      (next if p.hidden?) if !options[:include_hidden]
      (next if p.negative?) if options[:only_positive]
      (next if p.positive?) if options[:only_negative]
      result += p.amount_to(target_code)
    end
    return result
  end

  # 资产能以新台币或其他币种结算所有资产的利息总值
  def self.lixi( target_code = :twd, options = {} )
    result = 0
    all.each do |p|
      (next if p.hidden?) if !options[:include_hidden]
      result += p.lixi(target_code)
    end
    return result
  end

  # 资产能以新台币或其他币种结算所有资产包含利息的净值
  def self.net_value( target_code = :twd, options = {} )
    value(target_code,options) + lixi(target_code,options)
  end

  # 资产列表能显示3月底以来资产净值平均月增减额度
  def self.net_growth_ave_month( target_code = :twd, options = {} )
    if target_code == :twd
      start_value = $net_start_value
    elsif target_code == :cny
      start_value = $net_start_value * self.new.twd_to_cny
    end
    (net_value(target_code,options)-start_value)/pass_days*30
  end

  # 取出所有数据集并按照等值台币由大到小排序
  def self.all_sort( is_admin = false )
    scope = is_admin ? 'all' : 'all_visible'
    eval("#{scope}.sort_by{|p| p.amount_to}.reverse")
  end

  # 只回传所有非隐藏的资产
  def self.all_visible
    all.select {|p| !p.hidden? }
  end

  def self.clear_amount( property_id )
    find(property_id).update_attribute(:amount,0)
  end

  # 要写入记录列表的值
  def record_value
    amount_to(:twd).to_i
  end

  # 计算贷款利息
  def lixi( target_code = :twd )
    interest ? \
      (amount * (interest.rate.to_f/100/365) * \
      (Date.today-interest.start_date).to_i) * \
      (target_rate(target_code)/currency.exchange_rate) : 0
  end

  # 将此资产设置为隐藏资产
  def set_as_hidden
    update_attribute(:is_hidden, true)
  end

  # 回传此资产是否为隐藏资产
  def hidden?
    is_hidden
  end

  # 除了数字资产以小数点8位显示外其余为小数点2位
  def value
    to_amount(amount,currency.is_digital?)
  end

  # 资产金额是否为正值
  def positive?
    amount >= 0 ? true : false
  end

  # 资产金额是否为负值
  def negative?
    amount < 0 ? true : false
  end

  # 计算资产占比
  def proportion( input_value = false )
    if positive?
      return amount_to(:twd)/Property.value(:twd, \
        only_positive: true, include_hidden: input_value) *100
    elsif negative?
      return amount_to(:twd)/Property.value(:twd, \
        only_negative: true, include_hidden: input_value) *100
    end
  end

  # 更新资产金额
  def update_amount( new_amount )
    self.amount = new_amount
    save
  end

end
