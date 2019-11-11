class Record < ApplicationRecord

  validates \
    :class_name,
      presence: {
        message: $record_class_name_blank_err }
  validates \
    :oid,
      presence: {
        message: $record_oid_blank_err }
  validates \
    :value,
      presence: {
        message: $record_value_blank_err },
      numericality: {
        message: $record_value_nan_err }

end
