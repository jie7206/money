class DealRecord < ApplicationRecord

  validates \
    :symbol,
      presence: {
        message: $deal_record_symbol_blank_err }
  validates \
    :price,
      presence: {
        message: $deal_record_price_blank_err },
      numericality: {
        greater_than: 0,
        message: $deal_record_price_type_err }
  validates \
    :amount,
      presence: {
        message: $deal_record_amount_blank_err },
      numericality: {
        greater_than: 0,
        message: $deal_record_amount_type_err }
  validates \
    :earn_limit,
      numericality: {
        greater_than_or_equal_to: 0,
        message: $deal_record_earn_limit_type_err }
  validates \
    :loss_limit,
      numericality: {
        greater_than_or_equal_to: 0,
        message: $deal_record_loss_limit_type_err }

  before_validation :set_default

  # 回传火币账号所有资产总值
  def self.twd_of_acc_id
    twd_of_acc_id = 0.0
    Property.tagged_with(self.get_huobi_acc_id).each do |p|
      if p.name.include? 'BTC' or p.name.include? 'USDT'
        twd_of_acc_id += p.amount_to
      end
    end
    return twd_of_acc_id
  end

  # 回传火币账号的BTC现值
  def self.btc_cny
    Property.tagged_with(self.get_huobi_acc_id).each do |p|
      if p.name.include? 'BTC'
        return p.amount_to(:cny)
      end
    end
    return 0
  end

  # 回传火币账号所有持有的BTC资产
  def self.twd_of_btc
    twd_of_btc = 0.0
    Property.tagged_with(self.get_huobi_acc_id).each {|p| twd_of_btc = p.amount_to if p.name.include? 'BTC'}
    return twd_of_btc
  end

  # 回传目前仓位
  def self.btc_level
    return (self.twd_of_btc/self.twd_of_acc_id)*100
  end

  # 回传剩余资金
  def self.usdt_amount
    Property.tagged_with(self.get_huobi_acc_id).each do |p|
      return p.amount if p.name.include? 'USDT'
    end
    return 0
  end

  # 回传交易所内剩余的比特币
  def self.btc_amount
    Property.tagged_with(self.get_huobi_acc_id).each do |p|
      return p.amount if p.name.include? 'BTC'
    end
    return 0
  end

  # 回传未交易的比特币总数
  def self.unsell_amount
    unsell_records.sum {|r| r.amount*(1-$fees_rate)}
  end

  # 回传剩余比特币
  def self.btc_and_usdt_to_cny
    result = 0
    Property.tagged_with(self.get_huobi_acc_id).each do |p|
      result += p.amount_to(:cny) if p.name.include? 'BTC' or p.name.include? 'USDT'
    end
    return result
  end

  # 回传剩余比特币
  def self.total_amount
    total_amount = 0
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0").each {|dr| total_amount += dr.amount-dr.fees}
    return total_amount
  end

  # 回传总成本
  def self.total_cost
    total_cost = 0
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0").each {|dr| total_cost += dr.price*dr.amount}
    return total_cost
  end

  # 回传所有交易的总成本(跨越不同账号)
  def self.sum_of_total_cost
    total_cost = 0
    where("auto_sell = 0").each {|dr| total_cost += dr.price*dr.amount}
    return total_cost
  end

  # 回传所有交易的均价(跨越不同账号)
  def self.total_ave_cost
    total_amount = 0
    where("auto_sell = 0").each {|dr| total_amount += dr.amount}
    if total_amount > 0
      return self.sum_of_total_cost/total_amount
    else
      return 0
    end
  end

  # 回传均价
  def self.ave_cost
    total_amount = 0
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0").each {|dr| total_amount += dr.amount - dr.fees}
    if total_amount > 0
      return self.total_cost/total_amount
    else
      return 0
    end
  end

  # 回传损益
  def self.profit_cny(input_price=1/$btc_exchange_rate)
    if total_amount = self.total_amount and total_amount > 0.00000001
        input_price = 0 if !input_price
        btc_total_value = input_price*total_amount
        return (btc_total_value.to_f-self.total_cost)*self.new.usdt_to_cny
    else
        return 0
    end
  end

  # 所有已实现损益
  def self.total_real_profit
    return real_sell_records.sum {|dr| dr.real_profit}
  end

  # 所有未卖出损益
  def self.total_unsell_profit
    result = 0
    price_now = DealRecord.first.price_now if DealRecord.first
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0").each do |dr|
      result += (price_now-dr.price)*(dr.amount*(1-$fees_rate))
    end
    return result*(DealRecord.new.usdt_to_cny)
  end

  # 获取未卖出的交易笔数
  def self.unsell_count
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0").size
  end

  # 获取未卖出且标示为优先卖出的交易笔数
  def self.first_unsell_count
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0 and first_sell = 1").size
  end

  # 获取已卖出的交易笔数
  def self.sell_count
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 1").size
  end

  # 获取已卖出的交易记录
  def self.sell_records
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 1 and real_profit != 0")
  end

  # 获取已卖出的交易记录
  def self.trezor_records
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 1 and real_profit = 0")
  end

  # 计算最初几笔未卖出交易记录的损益值(¥)
  def self.top_n_profit( n, attr = :earn_or_loss )
    if self.unsell_count > 0
      result = 0
      where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0").order('first_sell desc,price').limit(n).each do |dr|
        result += dr.send(attr).to_f
      end
      return result
    else
      return 0
    end
  end

  # 第一笔未卖出交易记录的损益值(¥)
  def self.first_profit
    return self.top_n_profit(1)
  end

  # 尚未合并的已实现损益总值
  def self.uncombined_real_profit
    result = 0
    sql = "account = '#{self.get_huobi_acc_id}' and auto_sell = 1"
    count = sell_count
    select_count = (count != 1) ? count-1 : 1
    where(sql).order('created_at desc').limit(select_count).each do |dr|
      result += dr.real_profit.to_f
    end
    return result.to_i
  end

  # 回传未卖出交易
  def self.unsell_records
    return where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0")
  end

  # 清空未卖出交易
  def self.clear_unsell_records
    where("account = '#{self.get_huobi_acc_id}' and auto_sell = 0").delete_all
  end

  def self.real_sell_records
    sell_records.where.not(order_id: [nil, ""])
  end

  # 是否已经达到可以再次卖出的时间
  def self.over_sell_time?
    sell_sec = get_invest_params(22).to_i
    last_sell_time = where("account = '#{self.get_huobi_acc_id}' and auto_sell = 1").where.not(order_id: [nil, ""]).order("updated_at desc").first.updated_at
    pass_sec = (Time.now - last_sell_time).to_i
    if pass_sec > sell_sec
      return true
    else
      return false
    end
  end

  # 是否已经达到可以再次买入的时间
  def self.over_buy_time?
    enable_to_buy?
  end

  # 超出可买入时间的秒数
  def self.over_buy_time_sec
    buy_sec = get_invest_params(0).to_i
    begin
      last_buy_time = unsell_records.order("created_at desc").first.created_at
    rescue
      last_buy_time = real_sell_records.order("updated_at desc").first.updated_at
    end
    pass_sec = (Time.now - last_buy_time).to_i
    return pass_sec - buy_sec # 如果到达可买时间，则回传超过几秒
  end

  # 是否已经达到可以再次买入的时间
  def self.enable_to_buy?
    over_buy_time_sec > 0 ? true : false
  end

  # 超出可卖出时间的秒数
  def self.over_sell_time_sec
    sell_sec = get_invest_params(22).to_i
    last_sell_time = real_sell_records.order("updated_at desc").first.updated_at
    pass_sec = (Time.now - last_sell_time).to_i
    return pass_sec - sell_sec # 如果到达可卖时间，则回传超过几秒
  end

  # 是否已经达到可以再次卖出的时间
  def self.enable_to_sell?
    over_sell_time_sec > 0 ? true : false
  end

  # 交易列表上方显示24H已实现损益以便将获利每日转入冷钱包
  def self.real_profit_of_24h( from_time = (Time.now - 24.hour).to_s(:db) )
    return real_sell_records.where("updated_at > '#{from_time}'").sum {|r| r.real_profit}
  end

  # 平均每秒的已实现损益值
  def self.real_profit_ave_sec( total_real_profit = self.total_real_profit )
    first_sell_time = real_sell_records.order("updated_at").first.updated_at
    pass_sec = (Time.now - first_sell_time).to_i
    return total_real_profit.to_f/pass_sec
  end

  # 新增钱包凑数链接以方便凑齐当日存入到冷钱包的比特币数量
  def self.make_count_records( count_goal )
    result = []
    sum = 0
    min_amount = 0.0008
    # 由未卖转到钱包
    if count_goal > 0
      where("auto_sell = 0 and account = '#{get_huobi_acc_id}' and amount < #{min_amount} ").order('amount').each do |dr|
        result << dr
        sum += dr.amount
        return result if sum >= count_goal
      end
      where("auto_sell = 0 and account = '#{get_huobi_acc_id}' and amount > #{min_amount}").order('price asc').each do |dr|
        result << dr
        sum += dr.amount
        return result if sum >= count_goal
      end
    # 由钱包转到未卖
    elsif count_goal < 0
      where("auto_sell = 1 and real_profit = 0 and account = '#{get_huobi_acc_id}' and amount > #{min_amount}").order('price desc').each do |dr|
        result << dr
        sum += dr.amount
        return result if sum >= count_goal.abs
      end
    else
      return []
    end
  end

  # 交易列表能显示两个交易所放入到冷钱包的购买成本均价
  def self.trezor_total_cost
    trezor_records.sum {|r| r.price*r.amount}
  end

  # 交易列表能显示两个交易所放入到冷钱包的购买成本均价
  def self.trezor_total_amount
    trezor_records.sum {|r| r.amount}
  end

  # 显示币种
  def bi
    symbol.sub('usdt','').upcase
  end

  # 显示等值人民币
  def cny_amount
    (price*amount)*usdt_to_cny
  end

  # 显示等值人民币
  def cny_amount_now
    if rate = eval("$#{bi.downcase}_exchange_rate")
      btc_to_usdt = 1.0/rate
    else
      btc_to_usdt = 1.0/Currency.find_by_code(bi.upcase).exchange_rate
    end
    deal_type.index('buy') ? \
      to_n((btc_to_usdt*amount*(1-$fees_rate))*usdt_to_cny,2) : ''
  end

  # 盈亏
  def earn_or_loss
    deal_type.index('buy') ? \
      to_n(cny_amount_now.to_f-cny_amount.to_f,2) : ''
  end

  # 数字货币现价
  def price_now
    if rate = eval("$#{bi.downcase}_exchange_rate")
      return 1.0/rate
    else
      return 1.0/Currency.find_by_code(bi.upcase).exchange_rate
    end
  end

  # 扣除费用而实际得到的数量
  def real_amount
    amount - fees
  end

  # 扣除交易费后的实际可卖出的成交量
  def amount_fees
    real_amount
  end

  # 回传止盈价格
  def earn_limit_price
    earn_limit > 0 ? \
      to_n((earn_limit+price*real_amount*usdt_to_cny)/(real_amount*usdt_to_cny*(1-$fees_rate))) : 0
  end

  # 回传止损价格
  def loss_limit_price
    (loss_limit > 0 and loss_limit < price*real_amount*usdt_to_cny) ? \
      to_n((price*real_amount-loss_limit/usdt_to_cny)/(real_amount*(1-$fees_rate))) : 0
  end

  # 如果没输入栏位值则设定預設值
  def set_default
    self.earn_limit = 0 if !self.earn_limit
    self.loss_limit = 0 if !self.loss_limit
  end

  # 清空下单编号
  def clear_order
    if oo = OpenOrder.find_by_order_id(self.order_id)
      oo.destroy
    end
    update_attribute(:order_id,'')
  end

end
