require 'rails_helper'

RSpec.describe '模型测试(Property)', type: :model do

  fixtures :currencies

  specify '资产若无名称和金额则无法新建并能显示错误讯息' do
    expect_field_value_not_be_nil :property, :name, $property_name_blank_err
    expect_field_value_not_be_nil :property, :amount, $property_amount_blank_err
    expect_field_value_not_be_nil :property, 'name,amount'
  end

  specify '资产名称不能超过30个字元并能显示错误讯息' do
    expect_field_value_not_too_long :property, :name, $property_name_maxlength,  $property_name_len_err
  end

  specify '资产金额非数字形态能显示错误讯息' do
    expect_field_value_must_be_a_number :property, :amount, $property_amount_nan_err
  end

  specify '#99[模型层]资产若没有关联的货币种类则无法新建' do
    property = build(:property, currency: nil)
    expect(property).not_to be_valid
  end

  specify '#100[模型层]资产若没有关联的货币种类则无法更新' do
    property = create(:property)
    property.currency = nil
    property.save
    expect(property.errors.messages[:currency]).not_to be_blank
  end

  specify '#101[模型层]每笔资产的金额能换算成其他币种' do
    p = create(:property, amount: 100.0, currency: currencies(:twd))
    # 查不到该币别则返回原值
    expect(p.amount_to(:unknow)).to eq 100.0
    # 从自身的币别(台币)转换成人民币和美元
    expect(p.amount_to(:cny)).to eq 100.0*(7.0/31.0)
    expect(p.amount_to(:usd)).to eq 100.0*(1.0/31.0)
  end

  specify '#102[模型层]资产能以新台币或其他币种结算所有资产的总值' do
    create_3_different_currency_properties
    rate = 31.0 # 确保值不被其他测试修改而导致测试失败
    currencies(:twd).update_attribute(:exchange_rate, rate)
    expect(Property.total(:twd).to_i).to eq (100+100*(rate/7.0)+100*(rate/1.0)).to_i
  end


  specify '#103[模型层]汇率更新后所有资产的总值也能相应更新' do
    create_3_different_currency_properties
    new_rate = 33.5
    currencies(:twd).update_attribute(:exchange_rate, new_rate)
    expect(Property.total(:twd).to_i).to eq (100+100*(new_rate/7.0)+100*(new_rate/1.0)).to_i
    # 新增一种货币
    add_rate = 1.7174
    dem = create(:currency, code: 'dem', exchange_rate: add_rate)
    expect(Property.total(:dem).to_i).to eq (100*(add_rate/new_rate)+100*(add_rate/7.0)+100*(add_rate/1.0)).to_i
  end

end
