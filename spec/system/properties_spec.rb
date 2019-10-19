require 'rails_helper'

RSpec.describe '系统测试(Properties)', type: :system do

  before do
    visit login_path
    fill_in 'pincode', with: $pincode
    click_on '登入'
  end

  describe '成功用例' do

    specify '能通过表单新增一笔资产记录' do
      visit new_property_path
      fill_in 'property[name]', with: '我的工商银行账户'
      fill_in 'property[amount]', with: 99.99
      find('#create_new_property').click
      expect(current_path).to eq properties_path
      expect(page).to have_content '我的工商银行账户'
      expect(page).to have_content 99.99
      expect(page).to have_selector '.alert-notice' 
    end

    describe '修改与删除' do

      let(:property) { create(:property) }

      specify '能通过表单修改资产的名称' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        fill_in 'property[name]', with: '我的中国银行账户'
        find('#update_new_property').click
        expect(current_path).to eq properties_path
        expect(page).to have_content '我的中国银行账户'
      end

      specify '能通过表单修改资产的金额'
      specify '能通过表单删除一笔资产记录'

    end


  end

  describe '失败用例' do

    specify '当资产没有名称时无法新建'
    specify '当资产没有名称时无法更新'
    specify '当资产没有金额时无法新建'
    specify '当资产没有金额时无法更新'
    specify '当资产名称过长时无法新建或更新'
    specify '当资产金额不为正数时无法新建或更新'

  end

end
