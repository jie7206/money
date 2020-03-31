class ApplicationRecord < ActiveRecord::Base

  include ApplicationHelper
  self.abstract_class = true

  # 从起算日到今天为止已经经过几天
  def self.pass_days( from_date = $net_start_date, to_date = Date.today )
    (to_date-from_date).to_i
  end

  # 给模型添加向上排序方法
  def self.order_up( id, field = :order_num )
    ids = []
    self.all.order(field).each {|o| ids << o.id}
    ori_index = ids.index(id.to_i)
    if ori_index != 0
      ids[ori_index] = ids[ori_index-1]
      ids[ori_index-1] = id.to_i
      ids.each {|i| self.find(i).update_attribute(field,ids.index(i)+1)}
    end
  end

  # 给模型添加向下排序方法
  def self.order_down( id, field = :order_num )
    ids = []
    self.all.order(field).each {|o| ids << o.id}
    ori_index = ids.index(id.to_i)
    if ori_index != ids.size-1
      ids[ori_index] = ids[ori_index+1]
      ids[ori_index+1] = id.to_i
      ids.each {|i| self.find(i).update_attribute(field,ids.index(i)+1)}
    end
  end

  # 执行记录模型数值资料
  def self.record( class_name, oid, value )
    # 1.先确定有没有今天的记录
    today_record = Record.where(
      ["class_name = ? and oid = ? and
        created_at > ? and created_at < ?", class_name, oid,
        "#{Date.today} 00:00:00".to_time,
        "#{Date.today+1.day} 00:00:00".to_time]).last
    # 2.如果没有今天的记录则新增一笔
    if !today_record
      Record.create(class_name: class_name, oid: oid, value: value)
    else
    # 3.如果已有今天的记录则更新
      today_record.update_attribute(:value,value)
    end
  end

  # 更新模型里所有数据的记录资料
  def self.update_all_records
    all.each {|i| self.record(self.name, i.id, i.record_value)}
  end

  # 获取定投参数的值
  def self.get_invest_params( index )
    File.read($auto_invest_params_path).split(' ')[index]
  end

  # 读取火币APP的账号ID
  def self.get_huobi_acc_id
    get_invest_params(24)
  end

  # 更新某笔数据的记录资料
  def update_records
    Property.record(self.class.name, id, record_value)
  end

  # 设定货币的汇率值
  def set_exchange_rate( object, name )
    eval("$#{object.code.downcase}_exchange_rate = #{name}.exchange_rate")
  end

  # 取出目标货币的汇率值
  def target_rate( target_code = :twd )
    eval("$#{target_code.to_s.downcase}_exchange_rate")
  end

  # 将资产金额从自身的币别转换成其他币别(默认为新台币)
  def amount_to( target_code = :twd, self_rate = self.currency.exchange_rate.to_f )
    if trate = target_rate(target_code)
      result = amount*(trate.to_f/self_rate)
      if amount < 0 and lixi = self.lixi(target_code).to_i
        return result + lixi
      else
        return result
      end
    else
      return amount
    end
  end

  # USDT换成人民币
  def usdt_to_cny
    if $usdt_to_cny
      return $usdt_to_cny
    else
      return target_rate(:cny).to_f/target_rate(:usdt)
    end
  end

  # USDT换成新台币
  def usdt_to_twd
    target_rate(:twd).to_f/target_rate(:usdt)
  end

  # 新台币换成人民币
  def twd_to_cny
    target_rate(:cny).to_f/target_rate(:twd)
  end

  # 新台币换成USDT
  def twd_to_usdt
    target_rate(:usdt).to_f/target_rate(:twd)
  end

  # 人民币换成新台币
  def cny_to_twd
    target_rate(:twd).to_f/target_rate(:cny)
  end

  # 比特币换成人民币
  def btc_to_cny
    target_rate(:cny).to_f/target_rate(:btc)
  end

  # 人民币换成比特币
  def cny_to_btc
    target_rate(:btc).to_f/target_rate(:cny)
  end

end
