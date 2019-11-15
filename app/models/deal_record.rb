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
        greater_than: 0,
        message: $deal_record_earn_limit_type_err }
  validates \
    :loss_limit,
      numericality: {
        greater_than: 0,
        message: $deal_record_loss_limit_type_err }
end
