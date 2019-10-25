require 'rails_helper'

RSpec.describe '模型测试(Interest)', type: :model do

  specify '#104[模型层]利息没有对应资产、起算日和利率则无法新建并能显示错误讯息' do
    expect_field_value_not_be_nil :interest, :property
    expect_field_value_not_be_nil :interest, :start_date, $interest_start_date_blank_err
    expect_field_value_not_be_nil :interest, :rate, $interest_rate_blank_err
  end

  specify '#105[模型层]利息起算日必须是日期形态否则会产生错误讯息' do
    expect_field_value_must_be_a_date :interest, :start_date, $interest_start_date_type_err
  end

end
