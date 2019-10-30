class Interest < ApplicationRecord

  belongs_to :property

  validates \
    :start_date,
      presence: {
        message: $interest_start_date_blank_err },
      format: {
        with: /[1-9]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])/,
        message: $interest_start_date_type_err }

  validates \
    :rate,
      presence: {
        message: $interest_rate_blank_err },
      numericality: {
        greater_than_or_equal_to: 0,
        message: $interest_rate_type_err }

  # 利息金额
  def self.total( target_code = :twd )
    all.sum {|i| i.amount_to(target_code)}
  end

  # 利息金额
  def amount
    property.amount.to_f * (rate.to_f/100/365) * (Date.today-start_date).to_i
  end

  # 利息金额的等值台币
  def amount_to( target_code = :twd )
    target_exchange_rate = eval("$#{target_code.to_s.downcase}_exchange_rate")
    (amount * (target_exchange_rate/property.currency.exchange_rate)).to_i
  end

  # 利息币别
  def currency_name
    property.currency.name
  end

end
