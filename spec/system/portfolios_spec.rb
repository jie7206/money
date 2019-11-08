require 'rails_helper'

RSpec.describe '系统测试(Portfolios)', type: :system do

  let!(:portfolio) { create(:portfolio) }

  describe '以管理员登入' do

    before do
      visit login_path
      fill_in 'pincode', with: "#{$pincode}:#{$admincode}"
      find('#login').click
    end

    describe '资产组合列表' do

      before { visit portfolios_path }

      specify '#152[系统层]资产组合列表能显示组合名称、包含标签及排除标签' do
        expect(page).to have_content portfolio.name
        expect(page).to have_content portfolio.include_tags
        expect(page).to have_content portfolio.exclude_tags
      end

      specify '#153[系统层]在标签页中更新资产金额后能回到该标签页' do
        create_properties_with_tags
        visit properties_path
        click_on 'MYCASH'
        fill_in "new_amount_#{@twd_cash.id}", with: '12345.67'
        find("#property_#{@twd_cash.id}").click
        expect(page.html).to include '12345.67'
        expect(current_url).to include 'MYCASH'
      end

    end

    describe '新增资产组合' do

      before do
        visit portfolios_path
        find('#add_new_portfolio').click
      end

      describe '成功用例' do

        specify '#152[系统层]能通过资产组合表单成功建立一笔资产组合记录' do
          fill_in 'portfolio[name]', with: '我的比特币'
          fill_in 'portfolio[order_num]', with: 1
          fill_in 'portfolio[include_tags]', with: '比特币 个人资产'
          fill_in 'portfolio[exclude_tags]', with: '台湾'
          find('#create_new_portfolio').click
          expect(page).to have_selector '.alert-notice'
          expect(page).to have_content '我的比特币'
        end

      end

      describe '失败用例' do

        specify '#152[系统层]当资产组合没有名称时无法新建且显示错误讯息' do
          fill_in 'portfolio[name]', with: nil
          find('#create_new_portfolio').click
          expect(page).to have_content $portfolio_name_blank_err
        end

        specify '#152[系统层]当资产组合没有排序号码时无法新建且显示错误讯息' do
          fill_in 'portfolio[order_num]', with: nil
          find('#create_new_portfolio').click
          expect(page).to have_content $portfolio_order_num_blank_err
        end

        specify '#152[系统层]当资产组合排序号码不为大于零的数字时无法新建且显示错误讯息' do
          fill_in 'portfolio[order_num]', with: 'abcdefg'
          find('#create_new_portfolio').click
          expect(page).to have_content $portfolio_order_num_nap_err
          fill_in 'portfolio[order_num]', with: 0
          find('#create_new_portfolio').click
          expect(page).to have_content $portfolio_order_num_nap_err
          fill_in 'portfolio[order_num]', with: -1
          find('#create_new_portfolio').click
          expect(page).to have_content $portfolio_order_num_nap_err
        end

        specify '#152[系统层]当资产组合没有包含标签时无法新建且显示错误讯息' do
          fill_in 'portfolio[include_tags]', with: ''
          find('#create_new_portfolio').click
          expect(page).to have_content $portfolio_include_tags_blank_err
        end

      end

    end

    describe '修改与删除资产组合' do

      let!(:ori_portfolio_name) { portfolio.name }

      before do
        visit portfolios_path
        click_on portfolio.name
      end

      describe '成功用例' do

        specify '#152[系统层]能通过表单修改名称' do
          fill_in 'portfolio[name]', with: '所有新买的比特币'
          find('#update_portfolio').click
          expect(page).to have_selector '.alert-notice'
          expect(page).not_to have_content ori_portfolio_name
        end

        specify '#152[系统层]能通过表单修改排序号码' do
          fill_in 'portfolio[order_num]', with: 3
          find('#update_portfolio').click
          expect(page).to have_selector '.alert-notice'
        end

        specify '#152[系统层]能通过表单修改包含标签' do
          fill_in 'portfolio[include_tags]', with: '比特币 冷钱包 交易所'
          find('#update_portfolio').click
          expect(page).to have_selector '.alert-notice'
        end
        specify '#152[系统层]能通过表单修改排除标签' do
          fill_in 'portfolio[exclude_tags]', with: '家庭资产'
          find('#update_portfolio').click
          expect(page).to have_selector '.alert-notice'
        end

        specify '#152[系统层]能通过表单删除一笔资产组合记录' do
          find('#delete_portfolio').click
          expect(page).not_to have_content ori_portfolio_name
          expect(page).to have_selector '.alert-notice'
        end

      end

      describe '失败用例' do

        specify '#152[系统层]当资产组合没有名称时无法新建且显示错误讯息' do
          fill_in 'portfolio[name]', with: nil
          find('#update_portfolio').click
          expect(page).to have_content $portfolio_name_blank_err
        end

        specify '#152[系统层]当资产组合没有排序号码时无法新建且显示错误讯息' do
          fill_in 'portfolio[order_num]', with: nil
          find('#update_portfolio').click
          expect(page).to have_content $portfolio_order_num_blank_err
        end

        specify '#152[系统层]当资产组合排序号码不为大于零的数字时无法新建且显示错误讯息' do
          fill_in 'portfolio[order_num]', with: 'abcdefg'
          find('#update_portfolio').click
          expect(page).to have_content $portfolio_order_num_nap_err
          fill_in 'portfolio[order_num]', with: 0
          find('#update_portfolio').click
          expect(page).to have_content $portfolio_order_num_nap_err
          fill_in 'portfolio[order_num]', with: -1
          find('#update_portfolio').click
          expect(page).to have_content $portfolio_order_num_nap_err
        end

        specify '#152[系统层]当资产组合没有包含标签时无法新建且显示错误讯息' do
          fill_in 'portfolio[include_tags]', with: ''
          find('#update_portfolio').click
          expect(page).to have_content $portfolio_include_tags_blank_err
        end

      end

    end

  end

  describe '非管理员登入' do

    before do
      visit login_path
      fill_in 'pincode', with: $pincode
      find('#login').click
    end

    specify '#152[系统层]非管理员则无法显示资产组合编辑页面' do
      visit portfolios_path
      expect(current_path).to eq login_path
      visit edit_portfolio_path(portfolio)
      expect(current_path).to eq login_path
    end

  end

end
