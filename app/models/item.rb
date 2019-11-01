class Item < ApplicationRecord

  belongs_to :property

  validates \
    :price,
      presence: {
        message: $item_price_blank_err },
      numericality: {
        greater_than_or_equal_to: 0,
        message: $item_price_type_err }

  validates \
    :amount,
      presence: {
        message: $item_amount_blank_err },
      numericality: {
        greater_than_or_equal_to: 0,
        message: $item_amount_type_err }

end
