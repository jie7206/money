require 'rails_helper'

RSpec.describe '系统测试(DealRecords)', type: :system do

  describe '管理员登入' do

    let!(:deal_record) { create(:deal_record) }

    before do
      login_as_admin
      visit edit_deal_record_path(deal_record)
    end

    specify '#165[系统层]能更新交易记录属性' do
      fill_in 'deal_record[purpose]', with: '买新的电脑'
      fill_in 'deal_record[earn_limit]', with: 9000
      fill_in 'deal_record[loss_limit]', with: 500
      find('#update_deal_record').click
      expect(page).to have_selector '.alert-notice'
      expect(page).to have_content '买新的电脑'
      expect(page).to have_content 9000
      expect(page).to have_content 500
    end

    specify '#165[系统层]能通过表单删除一笔交易记录' do
      find('#delete_deal_record').click
      expect(page).not_to have_content deal_record.symbol
      expect(page).to have_selector '.alert-notice'
    end

  end

end
