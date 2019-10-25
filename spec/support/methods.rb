# 快速建立栏位应该为某个值的测试代码
def expect_field_value_should_be( model, fields, value )
  setting = (fields.to_s).split(',').map {|f| "#{f}: #{value.inspect}"}.join(',')
  command = "#{model.to_s} = build(:#{model.to_s}, #{setting})
             expect(#{model.to_s}).to be_valid"
  eval command
end

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

# 快速建立栏位必须为数字的测试代码
def expect_field_value_must_be_a_number( model, fields, error_msg = nil )
  expect_field_value_not_be( model, fields, 'abcd', error_msg )
  expect_field_value_should_be( model, fields, 0 )
  expect_field_value_should_be( model, fields, 10 )
  expect_field_value_should_be( model, fields, -10 )
  expect_field_value_should_be( model, fields, 100.00 )
  expect_field_value_should_be( model, fields, -100.00 )
end

# 快速建立栏位必须为日期的测试代码
def expect_field_value_must_be_a_date( model, fields, error_msg = nil )
  expect_field_value_not_be( model, fields, 'abcd', error_msg )
  expect_field_value_not_be( model, fields, 1234, error_msg )
  expect_field_value_not_be( model, fields, '1234@qq.com', error_msg )
  expect_field_value_should_be( model, fields, '2020-02-01' )
end

# 快速建立栏位必须大于零的测试代码
def expect_field_value_must_greater_than_zero( model, fields, error_msg = nil )
  expect_field_value_not_be( model, fields, 'abcd', error_msg )
  expect_field_value_not_be( model, fields, -2.8, error_msg )
  expect_field_value_not_be( model, fields, 0, error_msg )
  expect_field_value_should_be( model, fields, 10.10 )
end

# 快速建立栏位不能为负数的测试代码
def expect_field_value_must_be_positive( model, fields, error_msg = nil )
  expect_field_value_not_be( model, fields, -2.8, error_msg )
  expect_field_value_should_be( model, fields, 0 )
  expect_field_value_should_be( model, fields, 10 )
  expect_field_value_should_be( model, fields, 100.0 )
end

# 快速建立栏位文字不能太长的测试代码
def expect_field_value_not_too_long( model, fields, size = 50, error_msg = nil )
  expect_field_value_not_be( model, fields, 'a'*(size+1), error_msg )
  expect_field_value_should_be( model, fields, 'a'*size )
end

# 建立不同币别的资产
def create_different_currency_properties
  p1 = create(:property, amount: 1000.0, currency: currencies(:twd))
  p2 = create(:property, amount: 2000.0, currency: currencies(:cny))
  p3 = create(:property, amount: 3000.0, currency: currencies(:usd))
  p4 = create(:property, amount: -200.0, currency: currencies(:twd), name: '台币贷款')
  p5 = create(:property, amount: -100.0, currency: currencies(:cny), name: '人民币贷款')
  @ps = [p1, p2, p3, p4, p5]
end

# 根据create_different_currency_properties计算资产总值
def property_total_value_to( target_code, new_target_currency = nil )
  result = 0
  to_ex = new_target_currency ? new_target_currency.exchange_rate : currencies(target_code).exchange_rate
  @ps.each do |p|
    ex = p.currency.exchange_rate
    result += p.amount*(to_ex.to_f/ex.to_f)
  end
  return result.to_i
end
