require 'rails_helper'

RSpec.describe '模型测试(Item)', type: :model do

  specify '#133[模型层]商品若没有对应资产、单价和数量则无法新建并能显示错误' do
    expect_field_value_not_be_nil :item, :property
    expect_field_value_not_be_nil :item, :price, $item_price_blank_err
    expect_field_value_not_be_nil :item, :amount, $item_amount_blank_err
  end

end
