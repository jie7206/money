require 'rails_helper'

RSpec.describe '系统测试(Properties)', type: :system do

  describe '成功用例' do

    specify '能通过表单新增一笔资产记录' do
      visit new_property_path
      fill_in 'property[name]', with: '我的工商银行账户'
      fill_in 'property[amount]', with: 100.5
      find('#add_new_property').click
      expect(current_path).to eq '/propertys/index'
      expect(page).to have_content '我的工商银行账户'
    end

    specify '能通过表单删除一笔资产记录'
    specify '能通过表单修改资产的名称'
    specify '能通过表单修改资产的金额'

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
