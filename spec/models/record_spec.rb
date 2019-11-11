require 'rails_helper'

RSpec.describe '模型测试(Record)', type: :model do

  describe '基本验证' do

    specify '#160[模型层]数值记录若没有模型名称物件编号和数值则无法新建' do
      expect_field_value_not_be_nil :record, :class_name, $record_class_name_blank_err
      expect_field_value_not_be_nil :record, :oid, $record_oid_blank_err
      expect_field_value_not_be_nil :record, :value, $record_value_blank_err
    end

    specify '#160[模型层]数值不为数字时能显示错误讯息' do
      expect_field_value_must_be_a_number :record, :value, $record_value_nan_err
    end

  end

end
