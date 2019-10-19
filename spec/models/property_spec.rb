require 'rails_helper'

RSpec.describe '模型测试(Property)', type: :model do

  specify '新建资产时若无名称和金额则无法建立' do
    property = build(:property, name: nil)
    expect(property).not_to be_valid
    property = build(:property, amount: nil)
    expect(property).not_to be_valid
    property = build(:property, name: nil, amount: nil)
    expect(property).not_to be_valid
  end

  specify '资产名称空白时能显示中文错误讯息' do
    property = build(:property, name: nil)
    property.valid?
    expect(property.errors.messages[:name].join).to include $property_name_error_by_blank
  end

  specify '资产名称不能超过30个字元' do
    property = build(:property, name: 'a'*($property_name_maxlength+1))
    expect(property).not_to be_valid
  end

  specify '资产名称超过30个字元能显示中文错误讯息' do
    property = build(:property, name: 'a'*($property_name_maxlength+1))
    property.valid?
    expect(property.errors.messages[:name].join).to include $property_name_error_by_length
  end

  specify '资产金额空白时能显示中文错误讯息' do
    property = build(:property, amount: nil)
    property.valid?
    expect(property.errors.messages[:amount].join).to include $property_amount_error_by_blank
  end

  specify '资产金额必须是数字形态' do
    property = build(:property, amount: 'abcd')
    expect(property).not_to be_valid
  end

  specify '资产金额非数字形态能显示中文错误讯息' do
    property = build(:property, amount: 'abcd')
    property.valid?
    expect(property.errors.messages[:amount].join).to include $property_amount_error_by_numeric
  end

  specify '资产金额不能为负数' do
    property = build(:property, amount: -10.1)
    expect(property).not_to be_valid
    property = build(:property, amount: 0)
    expect(property).to be_valid
  end

  specify '资产金额为负数时能提示中文错误讯息' do
    property = build(:property, amount: -10.1)
    property.valid?
    expect(property.errors.messages[:amount].join).to include $property_amount_error_by_numeric
  end

end
