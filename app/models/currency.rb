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

  # 回传所有法币的数据集
  def self.legals
    all.reject(&:is_digital?)
  end

  # 回传所有数字货币的数据集
  def self.digitals
    all.select(&:is_digital?)
  end

  # 取得USDT兑美元汇率
  def self.usdt
    Currency.find_by_code('USDT')
  end

  # 自动新增货币汇率值到全域变数
  def add_or_renew_ex_rate
    set_exchange_rate self, 'self'
  end

  # 美元汇率值
  def to_rate
    if rate = eval("$#{code.downcase}_exchange_rate")
      return rate
    else
      return exchange_rate
    end
  end

  # 兑换美元汇率值
  def to_usd
    if rate = eval("$#{code.downcase}_exchange_rate")
      return 1.0/rate
    else
      return 1.0/exchange_rate
    end
  end

  # 回传是否为数字货币
  def is_digital?
    (symbol.nil? or symbol.empty?) ? false : true
  end

  # 显示数字符号
  def symbol_code
    is_digital? ? symbol.upcase : ''
  end

  # 如果是法币则显示汇率否则显示报价
  def rate_or_price
    is_digital? ? to_n(to_usd) : to_n(to_rate)
  end

  # 要写入记录列表的值
  def record_value
    rate_or_price
  end

end
