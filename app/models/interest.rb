class Interest < ApplicationRecord
  belongs_to :property

  validates \
    :start_date,
      presence: {
        message: $interest_start_date_blank_err }

  validates \
    :rate,
      presence: {
        message: $interest_rate_blank_err }

end
