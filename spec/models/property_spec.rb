require 'rails_helper'

RSpec.describe '模型测试(Property)', type: :model do

  specify '资产若无名称和金额则无法新建并能显示错误讯息' do
    expect_field_value_not_be_nil :property, :name, $property_name_blank_err
    expect_field_value_not_be_nil :property, :amount, $property_amount_blank_err
    expect_field_value_not_be_nil :property, 'name,amount'
  end

  specify '资产名称不能超过30个字元并能显示错误讯息' do
    expect_field_value_not_too_long :property, :name, $property_name_maxlength,  $property_name_len_err
  end

  specify '资产金额非数字形态能显示错误讯息' do
    expect_field_value_must_be_numeric :property, :amount, $property_amount_nan_err
  end

end
