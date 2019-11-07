class ApplicationRecord < ActiveRecord::Base

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

=begin

  def exe_order_up( class_name, object_id, order_field = "order_num" )
    @ids = []
    class_name.find(:all, :order => order_field).each {|d| @ids << d.id}
    @ori_index = @ids.index(object_id.to_i)
    if @ori_index != 0 then
      @ids[@ori_index] = @ids[@ori_index-1]
      @ids[@ori_index-1] = object_id.to_i
      exe_update_order_num( class_name, order_field, @ids )
    end
  end

  def exe_order_down( class_name, object_id, order_field = "order_num" )
    @ids = []
    class_name.find(:all, :order => order_field).each {|d| @ids << d.id}
    @ori_index = @ids.index(object_id.to_i)
    if @ori_index != @ids.size-1 then
      @ids[@ori_index] = @ids[@ori_index+1]
      @ids[@ori_index+1] = object_id.to_i
      exe_update_order_num( class_name, order_field, @ids )
    end
  end

  def exe_update_order_num( class_name, order_field = "order_num", ids = class_name.find(:all, :order => order_field) )
    ids.each {|i| class_name.find(i).update_attribute( order_field, ids.index(i)+1 )}
  end

=end

  # 设定货币的汇率值
  def set_exchange_rate( object, name )
    eval("$#{object.code.downcase}_exchange_rate = #{name}.exchange_rate")
  end

  # 取出目标货币的汇率值
  def target_rate( target_code = :twd )
    eval("$#{target_code.to_s.downcase}_exchange_rate")
  end

end
