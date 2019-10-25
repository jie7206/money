class Property < ApplicationRecord

  belongs_to :currency

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
  def self.total( target_code = :twd )
    result = 0
    all.each {|p| result += p.amount_to(target_code)}
    return result
  end

  # 回传所有贷款的记录
  def self.all_loan
    where 'amount < 0'
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

end
