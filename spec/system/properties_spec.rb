require 'rails_helper'

RSpec.describe '系统测试(Properties)', type: :system do

  before do
    visit login_path
    fill_in 'pincode', with: $pincode
    find('#login').click
  end

  describe '成功用例' do

    describe '新增资产' do

      specify '能通过表单新增一笔资产记录' do
        visit new_property_path
        fill_in 'property[name]', with: '我的工商银行账户'
        fill_in 'property[amount]', with: 99.99
        find('#create_new_property').click
        expect(current_path).to eq properties_path
        expect(page).to have_content '我的工商银行账户'
        expect(page).to have_content (99.99).to_i
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '修改与删除资产' do

      let!(:property) { create(:property) }

      specify '能通过表单修改资产的名称' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        fill_in 'property[name]', with: '我的中国银行账户'
        find('#update_property').click
        expect(current_path).to eq properties_path
        expect(page).to have_content '我的中国银行账户'
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单修改资产的金额' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        fill_in 'property[amount]', with: 1000.9865
        find('#update_property').click
        expect(current_path).to eq properties_path
        expect(page).to have_content 1000.98
        expect(page).not_to have_content 1000.9865
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单删除一笔资产记录' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        find('#delete_property').click
        expect(current_path).to eq properties_path
        expect(page).not_to have_content property.name
        expect(page).to have_selector '.alert-notice'
      end

    end


  end

  describe '失败用例' do

    describe '新增资产' do

      specify '当资产没有名称时无法新建且显示错误讯息' do
        visit new_property_path
        fill_in 'property[name]', with: ''
        find('#create_new_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_name_error_by_blank
      end

      specify '当资产没有金额时无法新建且显示错误讯息' do
        visit new_property_path
        fill_in 'property[amount]', with: nil
        find('#create_new_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_amount_error_by_blank
      end
      specify '当资产名称过长时无法新建且显示错误讯息' do
        visit new_property_path
        fill_in 'property[name]', with: 'a'*100
        find('#create_new_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_name_error_by_length
      end
      specify '当资产金额不为正数时无法新建且显示错误讯息' do
        visit new_property_path
        fill_in 'property[amount]', with: 'abcd'
        find('#create_new_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_amount_error_by_numeric
        fill_in 'property[amount]', with: -1.8
        find('#create_new_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_amount_error_by_numeric
      end

    end

    describe '修改与删除资产' do

      let!(:property) { create(:property) }

      specify '当资产没有名称时无法更新且显示错误讯息' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        fill_in 'property[name]', with: ''
        find('#update_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_name_error_by_blank
      end

      specify '当资产名称过长时无法更新且显示错误讯息' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        fill_in 'property[name]', with: 'a'*100
        find('#update_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_name_error_by_length
      end

      specify '当资产没有金额时无法更新且显示错误讯息' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        fill_in 'property[amount]', with: nil
        find('#update_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_amount_error_by_blank
      end

      specify '当资产金额不为正数时无法更新且显示错误讯息' do
        visit properties_path
        click_on property.name
        expect(current_path).to eq edit_property_path(property)
        fill_in 'property[amount]', with: 'abcd'
        find('#update_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_amount_error_by_numeric
        fill_in 'property[amount]', with: -10.8
        find('#update_property').click
        expect(page).to have_selector '#error_explanation'
        expect(page).to have_content $property_amount_error_by_numeric
      end

    end

  end

end
