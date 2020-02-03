# 以访客身份登入
def login_as_guest
  visit login_path
  fill_in 'pincode', with: $pincode
  find('#login').click
end

# 以管理员身份登入
def login_as_admin
  visit login_path
  fill_in 'pincode', with: "#{$pincode}:#{$admincode}"
  find('#login').click
end

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
  # amount值不能过大，否则测试包含利息的资产总净值会出错，已使用floor函数缓解此问题
  @twd = create(:property, amount: 132423321100.123, \
               currency: currencies(:twd), name: '台币现金')
  @cny = create(:property, amount: 132423321100.345, \
               currency: currencies(:cny), name: '人民币现金')
  @usd = create(:property, amount: 132423321100.567, \
               currency: currencies(:usd), name: '美元现金')
  @twd_loan = create(:property, amount: -2000000000.0, currency: currencies(:twd), name: '台币贷款')
  @cny_loan = create(:property, amount: -10000000.0, currency: currencies(:cny), name: '人民币贷款')
  @btc_hidden = create(:property, amount: 13000000.66085678, currency: currencies(:btc), name: '个人比特币', is_hidden: true)
  @btc_locked = create(:property, amount: 13000000.66085678, currency: currencies(:btc), name: '私人比特币', is_locked: true)
  @btc = create(:property, amount: 14000000.32874321, currency: currencies(:btc), name: '家庭比特币')
  @bch = create(:property, amount: 888000.53561621, currency: currencies(:bch), name: '个人比特现金')
  # 建立p4,p5的利息资料
  l1 = create(:interest, property: @twd_loan, start_date: 30.days.ago, rate: 6.5)
  l2 = create(:interest, property: @cny_loan, start_date: 90.days.ago, rate: 4.5)
  @ps = [@twd, @cny, @usd, @twd_loan, @cny_loan, @btc_hidden, @btc, @bch, @btc_locked]
  @ls = [l1, l2]
end

# 根据create_different_currency_properties计算资产总值
def property_total_value_to( target_code, new_target_currency = nil, options = {} )
  result = 0
  to_ex = new_target_currency ? \
    new_target_currency.exchange_rate : currencies(target_code).exchange_rate
  @ps.each do |p|
    (next if p.hidden?) if !options[:include_hidden]
    (next if p.negative?) if options[:only_positive]
    (next if p.positive?) if options[:only_negative]
    ex = p.currency.exchange_rate
    value = p.amount*(to_ex.to_f/ex.to_f)
    if p.amount < 0 and lixi = p.lixi(target_code).to_i
      result += value + lixi
    else
      result += value
    end
  end
  return result.to_i
end

# 包含利息在内的资产总净值计算
def property_total_net_value_to( target_code, new_target_currency = nil, options = {} )
  property_total_value_to( target_code, new_target_currency = nil, options = {} ) + \
    property_total_lixi_to( target_code, options = {} )
end

# 根据create_different_currency_properties计算资产的利息总值
def property_total_lixi_to( target_code, options = {} )
  result = 0
  @ls.each do |l|
    (next if l.property.hidden?) if !options[:include_hidden]
    result += l.property.lixi(target_code)
  end
  return result.to_f
end

# 以fixtures建立带有标签的资产
def create_properties_with_tags
  @twd_cash = create(:property, :twd)
  @cny_cash = create(:property, :cny)
  @btc_own = create(:property, :btc)
  @twd_cash.tag_list = 'TWD,MYCASH'
  @cny_cash.tag_list = 'CNY,MYCASH'
  @btc_own.tag_list = 'BTC,MINE'
  @twd_cash.save
  @cny_cash.save
  @btc_own.save
end
