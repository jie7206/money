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

    describe '失败用例' do

      specify '#109[系统层]当利息没有起算日时无法新建且显示错误讯息' do
        fill_in 'interest[start_date]', with: nil
        find('#create_new_interest').click
        expect(page).to have_content $interest_start_date_blank_err
      end

      specify '#109[系统层]当利息没有利率值时无法新建且显示错误讯息' do
        fill_in 'interest[rate]', with: nil
        find('#create_new_interest').click
        expect(page).to have_content $interest_rate_blank_err
      end

      specify '#109[系统层]当起算日格式不符时无法新建且显示错误讯息' do
        fill_in 'interest[start_date]', with: 'abcdefg'
        find('#create_new_interest').click
        expect(page).to have_content $interest_start_date_type_err
      end

      specify '#109[系统层]当利息为负数时无法新建且显示错误讯息' do
        fill_in 'interest[rate]', with: 'abcd'
        find('#create_new_interest').click
        expect(page).to have_content $interest_rate_type_err
        fill_in 'interest[rate]', with: -3.5
        find('#create_new_interest').click
        expect(page).to have_content $interest_rate_type_err
      end

    end

  end

  describe '修改与删除利息' do

    let!(:interest) { create(:interest) }
    let!(:ori_interest_name) { interest.property.name }

    before do
      visit interests_path
      click_on interest.property.name
    end

    describe '成功用例' do

      specify '#109[系统层]能通过表单修改对应的资产' do
        select '人民币贷款', from: 'interest[property_id]'
        find('#update_interest').click
        expect(page).to have_content '人民币贷款'
        expect(page).to have_selector '.alert-notice'
      end

      specify '#109[系统层]能通过表单修改起算日' do
        fill_in 'interest[start_date]', with: '2019-10-10'
        find('#update_interest').click
        expect(page).to have_content '2019-10-10'
        expect(page).to have_selector '.alert-notice'
      end

      specify '#109[系统层]能通过表单修改利率值' do
        fill_in 'interest[rate]', with: 2.8
        find('#update_interest').click
        expect(page).to have_content 2.8
        expect(page).to have_selector '.alert-notice'
      end

      specify '#109[系统层]能通过表单删除一笔利息记录' do
        find('#delete_interest').click
        expect(page).not_to have_content ori_interest_name
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '#109[系统层]当利息没有起算日时无法更新且显示错误讯息' do
        fill_in 'interest[start_date]', with: nil
        find('#update_interest').click
        expect(page).to have_content $interest_start_date_blank_err
      end

      specify '#109[系统层]当利息没有利率值时无法更新且显示错误讯息' do
        fill_in 'interest[rate]', with: nil
        find('#update_interest').click
        expect(page).to have_content $interest_rate_blank_err
      end

      specify '#109[系统层]当起算日格式不符时无法更新且显示错误讯息' do
        fill_in 'interest[start_date]', with: 'abcdefg'
        find('#update_interest').click
        expect(page).to have_content $interest_start_date_type_err
      end

      specify '#109[系统层]当利息为负数时无法更新且显示错误讯息' do
        fill_in 'interest[rate]', with: 'abcd'
        find('#update_interest').click
        expect(page).to have_content $interest_rate_type_err
        fill_in 'interest[rate]', with: -3.51
        find('#update_interest').click
        expect(page).to have_content $interest_rate_type_err
        fill_in 'interest[rate]', with: 3.51
        find('#update_interest').click
        expect(page).to have_content 3.51
      end

    end

  end

end
