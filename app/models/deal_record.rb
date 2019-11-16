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
    deal_type.index('buy') ? \
      to_n((Currency.find_by_code('BTC').to_usd*amount)*usdt_to_cny,1) : ''
  end

  # 盈亏
  def earn_or_loss
    deal_type.index('buy') ? \
      to_n(cny_amount_now.to_f-cny_amount.to_f,1) : ''
  end

end
