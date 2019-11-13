class Item < ApplicationRecord

  include ApplicationHelper

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

  after_save :update_property_amount

  # 回传房产的物件
  def self.house
    house = Property.where("name like '%燕大星苑%'").first
    if house
      id = house.id
    else
      id = self.first.property.id
    end
    find_by_property_id(id)
  end

  # 更新对应的资产金额
  def update_property_amount
    ori_amount = property.amount.to_i
    new_amount = (price * amount).to_i
    if new_amount - ori_amount != 0
      property.update_amount(new_amount)
      return true
    else
      return false
    end
  end

  # 要写入记录列表的值
  def record_value
    to_n(price)
  end

  def name
    "#{property.name}单价"
  end

end
