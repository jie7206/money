
# 快速建立栏位不能为某个值的测试代码
def expect_field_value_not_be( model, fields, value, error_msg )
  setting = (fields.to_s).split(',').map {|f| "#{f}: #{value.inspect}"}.join(',')
  command = "#{model.to_s} = build(:#{model.to_s}, #{setting})
             expect(#{model.to_s}).not_to be_valid"
  if error_msg and fields.to_s.split(',').size == 1
    eval command + "\n" +
      "#{model.to_s}.valid?
      expect(#{model.to_s}.errors.messages[#{fields.to_sym.inspect}].join).to \
        include '#{error_msg}'"
  else
    eval command
  end
end

# 快速建立栏位不能为空值的测试代码
def expect_field_value_not_be_nil( model, fields, error_msg = nil )
  expect_field_value_not_be( model, fields, nil, error_msg )
end

# 快速建立栏位不能为文字的测试代码
def expect_field_value_must_be_numeric( model, fields, error_msg = nil )
  expect_field_value_not_be( model, fields, 'abcd', error_msg )
end

# 快速建立栏位不能为文字的测试代码
def expect_field_value_not_too_long( model, fields, size = 50, error_msg = nil )
  expect_field_value_not_be( model, fields, 'a'*(size+1), error_msg )
end
