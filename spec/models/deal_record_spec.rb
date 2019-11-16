require 'rails_helper'

RSpec.describe '模型测试(DealRecord)', type: :model do

  describe '基本验证' do

    specify '#165[模型层]交易记录若没有币种、成交价、成交量则无法新建' do
      expect_field_value_not_be_nil :deal_record, :symbol, $deal_record_symbol_blank_err
      expect_field_value_not_be_nil :deal_record, :price, $deal_record_price_blank_err
      expect_field_value_not_be_nil :deal_record, :amount, $deal_record_amount_blank_err
    end

    specify '#165[模型层]成交价、成交量必须是正数否则显示错误讯息' do
      expect_field_value_must_greater_than_zero :deal_record, :price, $deal_record_price_type_err
      expect_field_value_must_greater_than_zero :deal_record, :amount, $deal_record_amount_type_err
      expect_field_value_must_be_positive :deal_record, :earn_limit, $deal_record_earn_limit_type_err
      expect_field_value_must_be_positive :deal_record, :loss_limit, $deal_record_loss_limit_type_err
    end

  end

end
