class DealRecord < ApplicationRecord

  validates \
    :symbol,
      presence: {
        message: $deal_record_symbol_blank_err }
  validates \
    :price,
      presence: {
        message: $deal_record_price_blank_err },
      numericality: {
        greater_than: 0,
        message: $deal_record_price_type_err }
  validates \
    :amount,
      presence: {
        message: $deal_record_amount_blank_err },
      numericality: {
        greater_than: 0,
        message: $deal_record_amount_type_err }
  validates \
    :earn_limit,
      numericality: {
        greater_than_or_equal_to: 0,
        message: $deal_record_earn_limit_type_err }
  validates \
    :loss_limit,
      numericality: {
        greater_than_or_equal_to: 0,
        message: $deal_record_loss_limit_type_err }

  before_validation :set_default

  # 显示币种
  def bi
    symbol.sub('usdt','').upcase
  end

  # 显示等值人民币
  def cny_amount
    (price*amount)*usdt_to_cny
  end

  # 显示等值人民币
  def cny_amount_now
    if rate = eval("$#{bi.downcase}_exchange_rate")
      btc_to_usdt = 1.0/rate
    else
      btc_to_usdt = 1.0/Currency.find_by_code(bi.upcase).exchange_rate
    end
    deal_type.index('buy') ? \
      to_n((btc_to_usdt*amount)*usdt_to_cny,2) : ''
  end

  # 盈亏
  def earn_or_loss
    deal_type.index('buy') ? \
      to_n(cny_amount_now.to_f-cny_amount.to_f,2) : ''
  end

  # 数字货币现价
  def price_now
    if rate = eval("$#{bi.downcase}_exchange_rate")
      return 1.0/rate
    else
      return 1.0/Currency.find_by_code(bi.upcase).exchange_rate
    end
  end

  # 扣除费用而实际得到的数量
  def real_amount
    amount - fees
  end

  # 回传止盈价格
  def earn_limit_price
    earn_limit > 0 ? \
      to_n((earn_limit+price*real_amount*usdt_to_cny)/(real_amount*usdt_to_cny*(1-$fees_rate))) : 0
  end

  # 回传止损价格
  def loss_limit_price
    (loss_limit > 0 and loss_limit < price*real_amount*usdt_to_cny) ? \
      to_n((price*real_amount-loss_limit/usdt_to_cny)/(real_amount*(1-$fees_rate))) : 0
  end

  # 如果没输入栏位值则设定預設值
  def set_default
    self.earn_limit = 0 if !self.earn_limit
    self.loss_limit = 0 if !self.loss_limit
  end

end
