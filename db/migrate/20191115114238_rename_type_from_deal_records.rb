class RenameTypeFromDealRecords < ActiveRecord::Migration[5.2]
  def change
    rename_column :deal_records, :type, :deal_type
    rename_column :deal_records, :auto_deal, :auto_sell
  end
end
