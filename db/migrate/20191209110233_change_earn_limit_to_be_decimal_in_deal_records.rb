class ChangeEarnLimitToBeDecimalInDealRecords < ActiveRecord::Migration[5.2]
  def change
    change_column :deal_records, :loss_limit, :decimal
    change_column :deal_records, :earn_limit, :decimal
  end
end
