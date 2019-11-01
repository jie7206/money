require 'rails_helper'

RSpec.describe '系统测试(Items)', type: :system do

  let!(:item) { create(:item) }

  before do
    visit login_path
    fill_in 'pincode', with: $pincode
    find('#login').click
  end

  describe '商品列表' do

    before { visit items_path }

    specify '#135[系统层]商品列表能显示对应资产的单价和数量' do
      expect(page).to have_content item.price.to_i
      expect(page).to have_content item.amount.to_i
    end

  end

  describe '新增商品' do

    before do
      visit items_path
      find('#add_new_item').click
    end

    describe '成功用例' do

      specify '#135[系统层]能通过商品表单成功建立一笔商品记录' do
        select '我的房产', from: 'item[property_id]'
        fill_in 'item[price]', with: 12100.78
        fill_in 'item[amount]', with: 49.50
        find('#create_new_item').click
        expect(page).to have_content '我的房产'
        expect(page).to have_content 12100
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '#135[系统层]当商品没有单价时无法新建且显示错误讯息' do
        fill_in 'item[price]', with: nil
        find('#create_new_item').click
        expect(page).to have_content $item_price_blank_err
      end

      specify '#135[系统层]当商品没有数量时无法新建且显示错误讯息' do
        fill_in 'item[amount]', with: nil
        find('#create_new_item').click
        expect(page).to have_content $item_amount_blank_err
      end

      specify '#135[系统层]当商品单价不为数字时无法新建且显示错误讯息' do
        fill_in 'item[price]', with: 'abcdefg'
        find('#create_new_item').click
        expect(page).to have_content $item_price_type_err
      end

      specify '#135[系统层]当商品数量不为数字时无法新建且显示错误讯息' do
        fill_in 'item[amount]', with: 'abcdefg'
        find('#create_new_item').click
        expect(page).to have_content $item_amount_type_err
      end

      specify '#135[系统层]当商品单价为负数时无法新建且显示错误讯息' do
        fill_in 'item[price]', with: -3.5
        find('#create_new_item').click
        expect(page).to have_content $item_price_type_err
      end

      specify '#135[系统层]当商品数量为负数时无法新建且显示错误讯息' do
        fill_in 'item[amount]', with: -3.5
        find('#create_new_item').click
        expect(page).to have_content $item_amount_type_err
      end

    end

  end

  describe '修改与删除商品' do

    let!(:ori_item_name) { item.property.name }
    let!(:stock) { create(:property, :stock)}

    before do
      visit items_path
      click_on item.property.name
    end

    describe '成功用例' do

      specify '#135[系统层]能通过表单修改对应的资产' do
        select '台积电', from: 'item[property_id]'
        find('#update_item').click
        expect(page).to have_content '台积电'
        expect(page).to have_selector '.alert-notice'
      end

      specify '#135[系统层]能通过表单修改单价' do
        fill_in 'item[price]', with: 1980.34
        find('#update_item').click
        expect(page).to have_content 1980
        expect(page).to have_selector '.alert-notice'
      end

      specify '#135[系统层]能通过表单修改数量' do
        fill_in 'item[amount]', with: 1328.67
        find('#update_item').click
        expect(page).to have_content 1328
        expect(page).to have_selector '.alert-notice'
      end

      specify '#135[系统层]能通过表单删除一笔商品记录' do
        find('#delete_item').click
        expect(page).not_to have_content ori_item_name
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '#135[系统层]当商品没有单价时无法更新且显示错误讯息' do
        fill_in 'item[price]', with: nil
        find('#update_item').click
        expect(page).to have_content $item_price_blank_err
      end

      specify '#135[系统层]当商品没有数量时无法更新且显示错误讯息' do
        fill_in 'item[amount]', with: nil
        find('#update_item').click
        expect(page).to have_content $item_amount_blank_err
      end

      specify '#135[系统层]当商品单价不为数字时无法更新且显示错误讯息' do
        fill_in 'item[price]', with: 'abcdefg'
        find('#update_item').click
        expect(page).to have_content $item_price_type_err
      end

      specify '#135[系统层]当商品单价为负数时无法更新且显示错误讯息' do
        fill_in 'item[price]', with: -100.10
        find('#update_item').click
        expect(page).to have_content $item_price_type_err
      end

      specify '#135[系统层]当商品数量不为数字时无法更新且显示错误讯息' do
        fill_in 'item[amount]', with: 'abcdefg'
        find('#update_item').click
        expect(page).to have_content $item_amount_type_err
      end

      specify '#135[系统层]当商品数量为负数时无法更新且显示错误讯息' do
        fill_in 'item[amount]', with: -100.10
        find('#update_item').click
        expect(page).to have_content $item_amount_type_err
      end

    end

  end

end
