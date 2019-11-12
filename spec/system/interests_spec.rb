require 'rails_helper'

RSpec.describe '系统测试(Interests)', type: :system do

  fixtures :currencies

  before do
    create_different_currency_properties
    login_as_guest
  end

  describe '利息列表' do

    before { visit interests_path }

    specify '#112[系统层]利息列表能显示对应资产的利息值、币别和等值台币' do
      expect(page).to have_content @ls[1].amount.to_i
      expect(page).to have_content @ls[1].currency_name
      expect(page).to have_content @ls[1].amount_to(:twd)
    end

    specify '#113[系统层]利息列表下方能以新台币和人民币显示利息的总金额' do
      expect(page).to have_selector '#interest_total_twd', text: Interest.total
      expect(page).to have_selector '#interest_total_cny', text: Interest.total(:cny)
    end

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

      specify '#140[系统层]用户在新建利息时不能看到隐藏资产以供选择' do
        property = create(:property, :usd_hidden)
        interest = create(:interest, property: property)
        visit new_interest_path
        expect(page).to have_selector '#interest_property_id', count: 1
        expect(page.html).not_to include property.name
      end

    end

    describe '失败用例' do

      specify '#109[系统层]当利息没有起算日时无法新建且显示错误讯息' do
        fill_in 'interest[start_date]', with: nil
        find('#create_new_interest').click
        expect(page).to have_content "#{$interest_start_date_blank_err}"
      end

      specify '#109[系统层]当利息没有利率值时无法新建且显示错误讯息' do
        fill_in 'interest[rate]', with: nil
        find('#create_new_interest').click
        expect(page).to have_content "#{$interest_rate_blank_err}"
      end

      specify '#109[系统层]当起算日格式不符时无法新建且显示错误讯息' do
        fill_in 'interest[start_date]', with: 'abcdefg'
        find('#create_new_interest').click
        expect(page).to have_content "#{$interest_start_date_type_err}"
      end

      specify '#109[系统层]当利息为负数时无法新建且显示错误讯息' do
        fill_in 'interest[rate]', with: 'abcd'
        find('#create_new_interest').click
        expect(page).to have_content "#{$interest_rate_type_err}"
        fill_in 'interest[rate]', with: -3.5
        find('#create_new_interest').click
        expect(page).to have_content "#{$interest_rate_type_err}"
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
        expect(page).to have_content "#{$interest_start_date_blank_err}"
      end

      specify '#109[系统层]当利息没有利率值时无法更新且显示错误讯息' do
        fill_in 'interest[rate]', with: nil
        find('#update_interest').click
        expect(page).to have_content "#{$interest_rate_blank_err}"
      end

      specify '#109[系统层]当起算日格式不符时无法更新且显示错误讯息' do
        fill_in 'interest[start_date]', with: 'abcdefg'
        find('#update_interest').click
        expect(page).to have_content "#{$interest_start_date_type_err}"
      end

      specify '#109[系统层]当利息为负数时无法更新且显示错误讯息' do
        fill_in 'interest[rate]', with: 'abcd'
        find('#update_interest').click
        expect(page).to have_content "#{$interest_rate_type_err}"
        fill_in 'interest[rate]', with: -3.51
        find('#update_interest').click
        expect(page).to have_content "#{$interest_rate_type_err}"
        fill_in 'interest[rate]', with: 3.51
        find('#update_interest').click
        expect(page).to have_content 3.51
      end

    end

  end

  describe '以管理员登入' do

    before { login_as_admin }

    specify '#141[系统层]管理员在新建利息时可看到隐藏资产以供选择' do
      property = create(:property, :usd_hidden)
      interest = create(:interest, property: property)
      visit new_interest_path
      expect(page).to have_selector '#interest_property_id', count: 1
      expect(page.html).to include property.name
    end

  end

end
