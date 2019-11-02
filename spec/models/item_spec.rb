require 'rails_helper'

RSpec.describe '模型测试(Item)', type: :model do

  describe '基本验证' do

    specify '#133[模型层]商品若没有对应资产、单价和数量则无法新建并能显示错误' do
      expect_field_value_not_be_nil :item, :property
      expect_field_value_not_be_nil :item, :price, $item_price_blank_err
      expect_field_value_not_be_nil :item, :amount, $item_amount_blank_err
    end

    specify '#134[模型层]商品单价或数量不能为负数否则显示错误讯息' do
      expect_field_value_must_be_positive :item, :price, $item_price_type_err
      expect_field_value_must_be_positive :item, :amount, $item_amount_type_err
    end

  end

  describe '进阶验证' do

    let!(:item) { create(:item, price: 12000.0, amount: 49.47) }
    let!(:ori_property_amount) { item.property.amount }

    specify '#137[模型层]当商品的单价更新则对应的资产金额也会更新' do
      item.price = 13000.0
      item.save
      expect(item.reload.property.amount).not_to eq ori_property_amount
      expect(item.property.amount.to_i).to eq (13000.0*item.amount).to_i
    end

    specify '#137[模型层]当商品的数量更新则对应的资产金额也会更新' do
      item.amount = 55.0
      item.save
      expect(item.reload.property.amount).not_to eq ori_property_amount
      expect(item.property.amount.to_i).to eq (item.price*55.0).to_i
    end

  end

end
