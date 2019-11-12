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

  specify '#92[模型层]货币汇率值不大于零时能显示错误讯息' do
    expect_field_value_must_greater_than_zero :currency, :exchange_rate, $currency_exchange_rate_nap_err
  end

  specify '#128[模型层]货币模型能显示某币种兑换美元的汇率值' do
    twd = build(:currency, :twd)
    expect(twd.to_usd.floor(3)).to eq (1/twd.exchange_rate).floor(3)
  end

  specify '#146[模型层]货币增加数字符号属性以分辨该币是否为法币' do
    twd = build(:currency, :twd, symbol: '')
    btc = build(:currency, :btc, symbol: 'btcusdt')
    expect(twd.is_digital?).to eq false
    expect(btc.is_digital?).to eq true
  end

end
