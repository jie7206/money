class Currency < ApplicationRecord

  has_many :properties

  validates \
    :name,
      presence: {
        message: $currency_name_blank_err },
      length: {
        maximum: $currency_name_maxlength,
        message: $currency_name_len_err }
  validates \
    :code,
      presence: {
        message: $currency_code_blank_err },
      length: {
        maximum: $currency_code_maxlength,
        message: $currency_code_len_err }
  validates \
    :exchange_rate,
      presence: {
        message: $currency_exchange_rate_blank_err },
      numericality: {
        message: $currency_exchange_rate_nan_err }
  validates \
    :exchange_rate,
      numericality: {
        greater_than: 0,
        message: $currency_exchange_rate_nap_err }
        
  # 自动新增货币汇率值到全域变数
  def self.generate_exchange_rates
    all.each do |c|
      eval "$#{c.code.downcase}_exchange_rate = c.exchange_rate"
    end
  end

end
