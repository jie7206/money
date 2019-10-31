require 'net/https'
require 'uri'

class Currency < ApplicationRecord

  include ApplicationHelper

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

  after_save :add_or_renew_ex_rate

  # 自动新增货币汇率值到全域变数
  def self.add_or_renew_ex_rates
    all.each {|c| c.add_or_renew_ex_rate}
  end

  # 自动新增货币汇率值到全域变数
  def add_or_renew_ex_rate
    set_exchange_rate self, 'self'
  end

  # 兑换美元汇率值
  def to_usd
    1.0/exchange_rate
  end

end
