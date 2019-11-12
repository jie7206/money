class Portfolio < ApplicationRecord

  include ApplicationHelper

  validates \
    :name,
      presence: {
        message: $portfolio_name_blank_err },
      length: {
        maximum: $portfolio_name_maxlength,
        message: $portfolio_name_len_err }
  validates \
    :mode,
      presence: {
        message: $portfolio_mode_blank_err }
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

  # 设定搜索模式
  def mode_name
    $modes.each do |str|
      return str.capitalize if mode == str[0]
    end
  end

  # 要写入记录列表的值
  def record_value
    twd_amount.to_i
  end

end
