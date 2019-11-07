class Portfolio < ApplicationRecord

  validates \
    :name,
      presence: {
        message: $portfolio_name_blank_err },
      length: {
        maximum: $portfolio_name_maxlength,
        message: $portfolio_name_len_err }
  validates \
    :include_tags,
      presence: {
        message: $portfolio_include_tags_blank_err },
      length: {
        maximum: $portfolio_include_tags_maxlength,
        message: $portfolio_include_tags_len_err }
  validates \
    :exclude_tags,
      length: {
        maximum: $portfolio_exclude_tags_maxlength,
        message: $portfolio_exclude_tags_len_err }
  validates \
    :order_num,
      presence: {
        message: $portfolio_order_num_blank_err }
  validates \
    :order_num,
      numericality: {
        greater_than: 0,
        message: $portfolio_order_num_nap_err }        
end
