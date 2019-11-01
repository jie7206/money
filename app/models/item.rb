class Item < ApplicationRecord

  belongs_to :property

  validates \
    :price,
      presence: {
        message: $item_price_blank_err }

  validates \
    :amount,
      presence: {
        message: $item_amount_blank_err }

end
