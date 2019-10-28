require 'rails_helper'

RSpec.describe '系统测试(Properties)', type: :system do

  fixtures :currencies

  before do
    visit login_path
    fill_in 'pincode', with: $pincode
    find('#login').click
  end

  describe '列表显示' do

    before do
      create_different_currency_properties
      visit properties_path
    end

    specify '#108[系统层]能在资产列表中显示包含利息的资产总净值' do
      expect(page).to have_selector '#properties_net_value_twd' , \
        text: (property_total_value_to(:twd) + property_total_lixi_to(:twd)).to_i
    end

    specify '#110[系统层]资产列表增加一栏位显示资产的利息值' do
      @ls.each {|l| expect(page).to have_content l.property.lixi.to_i}
    end

    specify '#111[系统层]能在资产列表的金额栏位中直接输入值后按回车更新' do
      p = @ps[0]
      fill_in "new_amount_#{p.id}", with: '57114.38'
      find("#property_#{p.id}").click
      expect(page.html).to include '57114.38'
    end

    specify '#114[系统层]资产列表能显示以人民币计算的资产总净值' do
      expect(page).to have_selector '#properties_net_value_cny' , \
        text: (property_total_value_to(:cny) + property_total_lixi_to(:cny)).to_i
    end

    specify '#115[系统层]资产能按照等值台币大小由高到低排序' do
      expect(page).to have_content /#{@ps[2].amount_to.to_i}(.)+#{@ps[1].amount_to.to_i}(.)+#{@ps[0].amount_to.to_i}/m
    end

    specify '#117[系统层]一般的登入在资产列表中看不到隐藏的资产' do
      hidden_property = @ps[5]
      expect(page).not_to have_content hidden_property.name
      expect(page).not_to have_content hidden_property.amount
    end

  end

  describe '新增资产' do

    before do
      visit properties_path
      find('#add_new_property').click
    end

    describe '成功用例' do

      specify '能通过表单新增一笔资产记录' do
        visit properties_path
        find('#add_new_property').click
        fill_in 'property[name]', with: '我的工商银行账户'
        fill_in 'property[amount]', with: 99.9999
        select '人民币', from: 'property[currency_id]'
        find('#create_new_property').click
        expect(page).to have_content '我的工商银行账户'
        expect(page.html).to include '99.9'
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '当资产没有名称时无法新建且显示错误讯息' do
        fill_in 'property[name]', with: ''
        find('#create_new_property').click
        expect(page).to have_content $property_name_blank_err
      end

      specify '当资产没有金额时无法新建且显示错误讯息' do
        fill_in 'property[amount]', with: nil
        find('#create_new_property').click
        expect(page).to have_content $property_amount_blank_err
      end

      specify '当资产名称过长时无法新建且显示错误讯息' do
        fill_in 'property[name]', with: 'a'*($property_name_maxlength+1)
        find('#create_new_property').click
        expect(page).to have_content $property_name_len_err
      end

      specify '当资产金额不为数字时无法新建且显示错误讯息' do
        fill_in 'property[amount]', with: 'abcd'
        find('#create_new_property').click
        expect(page).to have_content $property_amount_nan_err
      end

    end

  end

  describe '修改与删除资产' do

    let!(:property) { create(:property) }
    before do
      visit properties_path
      click_on property.name
    end

    describe '成功用例' do

      specify '能通过表单修改资产的名称' do
        fill_in 'property[name]', with: '我的中国银行账户'
        find('#update_property').click
        expect(page).to have_content '我的中国银行账户'
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单修改资产的金额' do
        fill_in 'property[amount]', with: 1000.9865
        find('#update_property').click
        expect(page.html).to include '1000.9'
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单删除一笔资产记录' do
        find('#delete_property').click
        expect(page).not_to have_content property.name
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '当资产没有名称时无法更新且显示错误讯息' do
        fill_in 'property[name]', with: ''
        find('#update_property').click
        expect(page).to have_content $property_name_blank_err
      end

      specify '当资产名称过长时无法更新且显示错误讯息' do
        fill_in 'property[name]', with: 'a'*($property_name_maxlength+1)
        find('#update_property').click
        expect(page).to have_content $property_name_len_err
      end

      specify '当资产没有金额时无法更新且显示错误讯息' do
        fill_in 'property[amount]', with: nil
        find('#update_property').click
        expect(page).to have_content $property_amount_blank_err
      end

      specify '当资产金额不为数字时无法更新且显示错误讯息' do
        fill_in 'property[amount]', with: 'abcd'
        find('#update_property').click
        expect(page).to have_content $property_amount_nan_err
      end

    end

  end

end
