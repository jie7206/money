require 'rails_helper'

RSpec.describe '模型测试(Portfolio)', type: :model do

  describe '基本验证' do

    specify '#152[模型层]资产组合若没有名称、包含标签及排序号码则无法新建' do
      expect_field_value_not_be_nil :portfolio, :name, $portfolio_name_blank_err
      expect_field_value_not_be_nil :portfolio, :include_tags, $portfolio_include_tags_blank_err
      expect_field_value_not_be_nil :portfolio, :order_num, $portfolio_order_num_blank_err
    end

    specify '#152[模型层]名称和标签若过长则无法新建' do
      expect_field_value_not_too_long :portfolio, :name, $portfolio_name_maxlength,  $portfolio_name_len_err
      expect_field_value_not_too_long :portfolio, :include_tags, $portfolio_include_tags_maxlength,  $portfolio_include_tags_len_err
      expect_field_value_not_too_long :portfolio, :exclude_tags, $portfolio_exclude_tags_maxlength,  $portfolio_exclude_tags_len_err
    end

    specify '#152[模型层]排序号码不大于零时能显示错误讯息' do
      expect_field_value_must_greater_than_zero :portfolio, :order_num, $portfolio_order_num_nap_err
    end

    specify '#157[模型层]资产组合新增模式属性以便能支持所有法币资产的查看' do
      expect_field_value_not_be_nil :portfolio, :mode, $portfolio_mode_blank_err
    end

  end

end
