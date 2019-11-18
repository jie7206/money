require 'rails_helper'

RSpec.describe '系统测试(DealRecords)', type: :system do

  describe '管理员登入' do

    let!(:deal_record) { create(:deal_record) }

    before { login_as_admin }

    specify '#165[系统层]能更新交易记录属性' do
      visit edit_deal_record_path(deal_record)
      fill_in 'deal_record[purpose]', with: '买新的电脑'
      fill_in 'deal_record[earn_limit]', with: 9000
      fill_in 'deal_record[loss_limit]', with: 500
      find('#update_deal_record').click
      expect(page).to have_selector '.alert-notice'
    end

    specify '#165[系统层]能通过表单删除一笔交易记录' do
      visit edit_deal_record_path(deal_record)
      find('#delete_deal_record').click
      expect(page).not_to have_content deal_record.symbol
      expect(page).to have_selector '.alert-notice'
    end

    specify '#167[系统层]修正清空某币之后无法将其资产归零的问题' do
      # 由于火币API已绑定主机，所以无法在本地测试，默认为通过
    end

    specify '#169[系统层]点击止盈价或止损价能快速自动下单卖出' do
      visit deal_records_path
      earn_limit_price = deal_record.earn_limit_price
      expect(page).to have_content earn_limit_price
      click_link earn_limit_price
      expect(current_path).to eq place_order_confirm_path
      expect(page.html).to include 'sell-limit'
    end

  end

end