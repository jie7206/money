require 'net/http'

class Property < ApplicationRecord

  include ApplicationHelper

  acts_as_taggable
  belongs_to :currency
  has_one :interest
  has_one :item

  after_create :update_records

  validates \
    :name,
      presence: {
        message: $property_name_blank_err },
      length: {
        maximum: $property_name_maxlength,
        message: $property_name_len_err }

  validates \
    :amount,
      presence: {
        message: $property_amount_blank_err } ,
      numericality: {
        message: $property_amount_nan_err }

  # 资产能以新台币或其他币种结算所有资产的总值
  def self.value( target_code = :twd, options = {} )
    result = 0
    all.each do |p|
      (next if p.hidden?) if !options[:include_hidden]
      (next if p.negative?) if options[:only_positive]
      (next if p.positive?) if options[:only_negative]
      result += p.amount_to(target_code)
    end
    return result
  end

  # 资产能以新台币或其他币种结算所有资产的利息总值
  def self.lixi( target_code = :twd, options = {} )
    result = 0
    all.each do |p|
      (next if p.hidden?) if !options[:include_hidden]
      result += p.lixi(target_code)
    end
    return result
  end

  # 资产能以新台币或其他币种结算所有资产包含利息的净值
  def self.net_value( target_code = :twd, options = {} )
    value(target_code,options) + lixi(target_code,options)
  end

  # 资产列表能显示3月底以来资产净值平均月增减额度
  def self.net_growth_ave_month( target_code = :twd, options = {} )
    if target_code == :twd
      start_value = $net_start_value
    elsif target_code == :cny
      start_value = $net_start_value * self.new.twd_to_cny
    end
    (net_value(target_code,options)-start_value)/pass_days*30
  end

  # 取出所有数据集并按照等值台币由大到小排序
  def self.all_sort( is_admin = false )
    scope = is_admin ? 'all' : 'all_visible'
    eval("#{scope}.sort_by{|p| p.amount_to}.reverse")
  end

  # 只回传所有非隐藏的资产
  def self.all_visible
    all.select {|p| !p.hidden? }
  end

  # 清空某个资产的金额
  def self.clear_amount( property_id )
    find(property_id).update_attribute(:amount,0)
  end

  # 贷款(含利息)的总额
  def self.total_loan_lixi
    value(:twd, only_negative: true).abs
  end

  # 贷款(含利息)的总额从台币换算成泰达币
  def self.total_loan_lixi_usdt
    total_loan_lixi*(new.twd_to_usdt)
  end

  def self.get_invest_param_from( file_path, index, to_number = true )
    value = File.read(file_path).split(' ')[index]
    if to_number
      return value.to_f
    else
      return value
    end
  end

  # 数字货币总资产换算成比特币
  def self.invest_to_btc( is_admin = false )
    cost1 = get_invest_param_from($auto_invest_params_path,25)
    amount1 = get_invest_param_from($auto_invest_params_path,26)
    cost2 = get_invest_param_from($auto_invest_params_path2,25)
    amount2 = get_invest_param_from($auto_invest_params_path2,26)
    real_ave_cost = (cost1+cost2)/(amount1+amount2)
    sell_profit1, unsell_profit1, ave_sec_profit1, real_p_24h1, trezor_cost1, trezor_amount1 = get_invest_param_from($auto_invest_params_path,28,false).split(':')
    sell_profit2, unsell_profit2, ave_sec_profit2, real_p_24h2, trezor_cost2, trezor_amount2 = get_invest_param_from($auto_invest_params_path2,28,false).split(':')
    total_real_profit = sell_profit1.to_f + sell_profit2.to_f
    total_unsell_profit = unsell_profit1.to_f + unsell_profit2.to_f
    ave_hour_profit = (ave_sec_profit1.to_f + ave_sec_profit2.to_f)*60*60
    total_real_p_24h = real_p_24h1.to_i + real_p_24h2.to_i
    trezor_ave_cost = (trezor_cost1.to_f+trezor_cost2.to_f)/(trezor_amount1.to_f+trezor_amount2.to_f)
    price_now = DealRecord.first.price_now if DealRecord.first
    price_p = (price_now/real_ave_cost-1)*100 # 现价与均价的比率(利率)
    p_btc = Property.tagged_with('比特币').sum {|p| p.amount}
    p_trezor = Property.tagged_with('冷钱包').sum {|p| p.amount}
    p_short = Property.tagged_with('短线').sum {|p| p.amount_to(:btc)}
    eq_btc = (p_trezor + p_short).floor(8)
    sim_ave_cost = total_loan_lixi_usdt/eq_btc
    # 比特币每1个百分点对应多少人民币
    btc_p = p_btc/(p_trezor + p_short)*100
    one_btc2cny = p_btc*(new.btc_to_cny)/btc_p
    if is_admin
      return eq_btc, btc_p, sim_ave_cost, real_ave_cost, trezor_ave_cost, price_p, one_btc2cny, total_real_profit.to_i.to_s + ' ', total_unsell_profit.to_i.to_s + ' ', ave_hour_profit.to_i.to_s + ' ', total_real_p_24h.to_s + ' '
    else
      p_fbtc = Property.tagged_with('家庭比特币').sum {|p| p.amount_to(:btc)}
      p_finv = Property.tagged_with('家庭投资').sum {|p| p.amount_to(:btc)}
      return p_finv.floor(8), p_fbtc/p_finv*100, sim_ave_cost, real_ave_cost, trezor_ave_cost, price_p, one_btc2cny, '', '', '', ''
    end
  end

  # 比特币价值与法币价值的比例
  def self.btc_legal_ratio
    btc_twd = (Property.tagged_with('比特币').sum {|p| p.amount_to(:twd)})
    legal_twd = (Property.tagged_with('法币').sum {|p| p.amount_to(:twd)})
    usdt_twd = (Property.tagged_with('泰达币').sum {|p| p.amount_to(:twd)})
    return btc_twd/(legal_twd+usdt_twd)
  end

  # 比特币的总成本
  def self.btc_total_cost_twd
    # 还没购买比特币的剩余可投资资金
    ps = new.get_properties_from_tags( '短线', '比特币' )
    # 比特币的总成本 = 总贷款 - 还没购买比特币的剩余可投资资金
    total_loan_lixi - (ps.sum {|p| p.amount_to(:twd)})
  end

  # 比特币的总成本从台币换算成泰达币
  def self.btc_total_cost_usdt
    btc_total_cost_twd*(new.twd_to_usdt)
  end

  # 冷钱包的总成本
  def self.trezor_total_cost_twd
    total_loan_lixi - (Property.tagged_with('短线').sum {|p| p.amount_to(:twd)})
  end

  # 冷钱包的总成本从台币换算成泰达币
  def self.trezor_total_cost_usdt
     trezor_total_cost_twd*(new.twd_to_usdt)
  end

  # 比特币的总数
  def self.total_btc_amount
    Property.tagged_with('比特币').sum {|p| p.amount}
  end

  # 计算比特币的成本均价
  def self.btc_ave_cost
    ps = Property.tagged_with('比特币')
    if ps.size > 0
      return btc_total_cost_usdt/(ps.sum {|p| p.amount})
    else
      return 0
    end
  end

  # 计算冷钱包的成本均价
  def self.trezor_ave_cost
    ps = Property.tagged_with('冷钱包')
    if ps.size > 0
      return trezor_total_cost_usdt/(ps.sum {|p| p.amount})
    else
      return 0
    end
  end

  # 计算冷钱包过去每月的获利率
  def self.ave_month_growth_rate
    ps = Property.tagged_with('冷钱包')
    if ps.size > 0
      cost = trezor_total_cost_twd
      months = pass_days.to_i/30
      if months > 0
        result = ((1+((ps.sum {|p| p.amount_to(:twd)})-cost)/cost)**(1.0/months)-1)*100
        if result < 0
          return 0
        else
          return result
        end
      else
        return 0
      end
    else
      return 0
    end
  end

  # 冷钱包目前的值
  def self.trezor_value_twd
    ps = Property.tagged_with('冷钱包')
    if ps.size > 0
      return ps.sum {|p| p.amount_to(:twd)}
    else
      return 0
    end
  end

  # 计算冷钱包下一年收益
  def self.cal_year_profit( br = "\n" )
    year_profit_p = ave_month_growth_rate > 0 ? (1+ave_month_growth_rate.to_f/100)**12 : 1
    profit_p_value = year_profit_p-1
    year_goal = (trezor_value_twd*year_profit_p).to_i
    year_profit = (trezor_value_twd*profit_p_value).to_i
    return "预估年化利率：#{format("%.2f", profit_p_value*100)}%" + br + "冷钱包年目标：#{year_goal}" + br + "冷钱包年获利：#{year_profit}" + br + "平均每月获利：#{year_profit/12}"
  end

  # 要写入记录列表的值
  def record_value
    amount_to(:twd).to_i
  end

  # 计算贷款利息
  def lixi( target_code = :twd )
    interest ? \
      (amount * (interest.rate.to_f/100/365) * \
      (Date.today-interest.start_date).to_i) * \
      (target_rate(target_code)/currency.exchange_rate) : 0
  end

  # 将此资产设置为隐藏资产
  def set_as_hidden
    update_attribute(:is_hidden, true)
  end

  # 将此资产设置为不可删除资产
  def set_as_locked
    update_attribute(:is_locked, true)
  end

  # 回传此资产是否为隐藏资产
  def hidden?
    is_hidden
  end

  # 回传此资产是否为不可删除资产
  def locked?
    is_locked
  end

  # 除了数字资产以小数点8位显示外其余为小数点2位
  def value
    to_amount(amount,currency.is_digital?)
  end

  # 资产金额是否为正值
  def positive?
    amount >= 0 ? true : false
  end

  # 资产金额是否为负值
  def negative?
    amount < 0 ? true : false
  end

  # 计算资产占比
  def proportion( input_value = false )
    if positive?
      return amount_to(:twd)/Property.value(:twd, \
        only_positive: true, include_hidden: input_value) *100
    elsif negative?
      return amount_to(:twd)/Property.value(:twd, \
        only_negative: true, include_hidden: input_value) *100
    end
  end

  # 更新资产金额
  def update_amount( new_amount )
    self.amount = new_amount
    save
  end

end
