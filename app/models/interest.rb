class Interest < ApplicationRecord
  belongs_to :property

  validates \
    :start_date,
      presence: {
        message: $interest_start_date_blank_err },
      format: {
        with: /[1-9]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])/,
        message: $interest_start_date_type_err
      }

  validates \
    :rate,
      presence: {
        message: $interest_rate_blank_err }

end
