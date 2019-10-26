class Property < ApplicationRecord

  belongs_to :currency
  has_one :interest

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
        message: $property_amount_blank_err },
      numericality: {
        message: $property_amount_nan_err }

  # 资产能以新台币或其他币种结算所有资产的总值
  def self.value( target_code = :twd )
    result = 0.0
    all.each {|p| result += p.amount_to(target_code)}
    return result.to_f
  end

  # 资产能以新台币或其他币种结算所有资产的利息总值
  def self.lixi( target_code = :twd )
    result = 0.0
    to_ex = eval "$#{target_code.to_s.downcase}_exchange_rate"
    all_loan.each {|p| result += p.cal_lixi*(to_ex/p.currency.exchange_rate).floor(2) if p.interest }
    return result.to_f
  end

  # 资产能以新台币或其他币种结算所有资产包含利息的净值
  def self.net_value( target_code = :twd )
    return (Property.value(target_code) - Property.lixi(target_code)).to_f
  end

  # 回传所有贷款的记录
  def self.all_loan
    where 'amount < 0.0'
  end

  # 将资产金额从自身的币别转换成其他币别(默认为新台币)
  def amount_to( target_code = :twd )
    target_exchange_rate = eval "$#{target_code.to_s.downcase}_exchange_rate"
    if target_exchange_rate
      return amount*(target_exchange_rate.to_f/self.currency.exchange_rate.to_f)
    else
      return amount
    end
  end

  # 计算贷款利息
  def cal_lixi
    (amount.abs * interest.rate.to_f/100/365 * (Date.today-interest.start_date).to_i).floor(2)
  end

end
