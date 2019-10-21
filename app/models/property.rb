class Property < ApplicationRecord

  validates :name,
    presence: { message: $property_name_error_by_blank },
    length: { maximum: $property_name_maxlength, message: $property_name_error_by_length }
  validates :amount,
    presence: { message: $property_amount_error_by_blank },
    numericality: {  message: $property_amount_error_by_numeric }

end
