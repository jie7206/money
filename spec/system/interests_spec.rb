require 'rails_helper'

RSpec.describe '系统测试(Interests)', type: :system do

  fixtures :currencies

  before do
    create_different_currency_properties
    visit login_path
    fill_in 'pincode', with: $pincode
    find('#login').click
  end

  describe '新增利息' do

    before do
      visit interests_path
      find('#add_new_interest').click
    end

    describe '成功用例' do

      specify '#107[系统层]能通过利息表单成功建立一笔利息记录' do
        select '台币贷款', from: 'interest[property_id]'
        fill_in 'interest[start_date]', with: '2019-10-01'
        fill_in 'interest[rate]', with: 6.50
        find('#create_new_interest').click
        expect(page).to have_content '台币贷款'
        expect(page).to have_content 6.50
        expect(page).to have_selector '.alert-notice'
      end

    end

  end

end
