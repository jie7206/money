require 'rails_helper'

RSpec.describe '模型测试(Currency)', type: :model do

  specify '货币若无名称、代码和汇率值则无法建立并能显示错误讯息' do
    expect_field_value_not_be_nil :currency, :name, $currency_name_blank_err
    expect_field_value_not_be_nil :currency, :code, $currency_code_blank_err
    expect_field_value_not_be_nil :currency, :exchange_rate, $currency_exchange_rate_blank_err
  end

  specify '货币名称、代码不能超过15个字元并能显示错误讯息' do
    expect_field_value_not_too_long :currency, :name, $currency_name_maxlength,  $currency_name_len_err
    expect_field_value_not_too_long :currency, :code, $currency_code_maxlength,  $currency_code_len_err
  end

  specify '货币汇率值非数字形态能显示错误讯息' do
    expect_field_value_must_be_numeric :currency, :exchange_rate, $currency_exchange_rate_nan_err
  end

end
