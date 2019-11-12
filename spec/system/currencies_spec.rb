require 'rails_helper'

RSpec.describe '系统测试(Currencies)', type: :system do

  fixtures :currencies

  before do
    login_as_guest
  end

  describe '新增货币' do

    before do
      visit currencies_path
      find('#add_new_currency').click
    end

    describe '成功用例' do

      specify '能通过表单新增一笔货币记录' do
        visit currencies_path
        find('#add_new_currency').click
        fill_in 'currency[name]', with: '人民币'
        fill_in 'currency[code]', with: 'CNY'
        fill_in 'currency[exchange_rate]', with: 7.0563
        find('#create_new_currency').click
        expect(page).to have_content '人民币'
        expect(page).to have_content 7.0563
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '当货币没有名称时无法新建且显示错误讯息' do
        fill_in 'currency[name]', with: ''
        find('#create_new_currency').click
        expect(page).to have_content $currency_name_blank_err
      end

      specify '当货币没有代码时无法新建且显示错误讯息' do
        fill_in 'currency[code]', with: nil
        find('#create_new_currency').click
        expect(page).to have_content $currency_code_blank_err
      end

      specify '当货币没有汇率值时无法新建且显示错误讯息' do
        fill_in 'currency[exchange_rate]', with: nil
        find('#create_new_currency').click
        expect(page).to have_content $currency_exchange_rate_blank_err
      end

      specify '当货币名称过长时无法新建且显示错误讯息' do
        fill_in 'currency[name]', with: 'a'*($currency_name_maxlength+1)
        find('#create_new_currency').click
        expect(page).to have_content $currency_name_len_err
      end

      specify '当货币代码过长时无法新建且显示错误讯息' do
        fill_in 'currency[code]', with: 'a'*($currency_name_maxlength+1)
        find('#create_new_currency').click
        expect(page).to have_content $currency_code_len_err
      end

      specify '当货币汇率值不为数字时无法新建且显示错误讯息' do
        fill_in 'currency[exchange_rate]', with: 'abcd'
        find('#create_new_currency').click
        expect(page).to have_content $currency_exchange_rate_nan_err
      end

      specify '#93[系统层]货币汇率值不为正数时无法新建且显示错误讯息' do
        fill_in 'currency[exchange_rate]', with: 0
        find('#create_new_currency').click
        expect(page).to have_content $currency_exchange_rate_nap_err
        fill_in 'currency[exchange_rate]', with: -1.8
        find('#create_new_currency').click
        expect(page).to have_content $currency_exchange_rate_nap_err
      end

    end

  end

  describe '修改与删除货币' do

    let!(:currency) { create(:currency) }
    before do
      visit currencies_path
      click_on currency.name
    end

    describe '成功用例' do

      specify '能通过表单修改货币的名称' do
        fill_in 'currency[name]', with: '美元'
        find('#update_currency').click
        expect(page).to have_content '美元'
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单修改货币的代码' do
        fill_in 'currency[name]', with: 'USD'
        find('#update_currency').click
        expect(page).to have_content 'USD'
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单修改货币的汇率值' do
        fill_in 'currency[exchange_rate]', with: 31.9865
        find('#update_currency').click
        expect(page).to have_content 31.9865
        expect(page).to have_selector '.alert-notice'
      end

      specify '能通过表单删除一笔货币记录' do
        find('#delete_currency').click
        expect(page).not_to have_content currency.name
        expect(page).to have_selector '.alert-notice'
      end

    end

    describe '失败用例' do

      specify '当货币没有名称时无法更新且显示错误讯息' do
        fill_in 'currency[name]', with: ''
        find('#update_currency').click
        expect(page).to have_content $currency_name_blank_err
      end

      specify '当货币名称过长时无法更新且显示错误讯息' do
        fill_in 'currency[name]', with: 'a'*($currency_name_maxlength+1)
        find('#update_currency').click
        expect(page).to have_content $currency_name_len_err
      end

      specify '当货币没有代码时无法更新且显示错误讯息' do
        fill_in 'currency[code]', with: ''
        find('#update_currency').click
        expect(page).to have_content $currency_code_blank_err
      end

      specify '当货币代码过长时无法更新且显示错误讯息' do
        fill_in 'currency[code]', with: 'a'*($currency_code_maxlength+1)
        find('#update_currency').click
        expect(page).to have_content $currency_code_len_err
      end

      specify '当货币没有汇率值时无法更新且显示错误讯息' do
        fill_in 'currency[exchange_rate]', with: nil
        find('#update_currency').click
        expect(page).to have_content $currency_exchange_rate_blank_err
      end

      specify '当货币汇率值不为数字时无法更新且显示错误讯息' do
        fill_in 'currency[exchange_rate]', with: 'abcd'
        find('#update_currency').click
        expect(page).to have_content $currency_exchange_rate_nan_err
      end

      specify '#147[系统层]非管理员看不到数字货币的符号属性' do
        btc = currencies(:btc)
        visit edit_currency_path(btc)
        expect(page).not_to have_selector '#currency_symbol'
      end

    end

  end

  describe '以管理员登入' do

    before do
      login_as_admin
    end

    specify '#147[系统层]只有管理员能设定数字货币的符号属性' do
      btc = currencies(:btc)
      visit edit_currency_path(btc)
      fill_in 'currency[symbol]', with: 'btcusdt'
      find('#update_currency').click
      expect(page).to have_selector '.alert-notice'
    end

  end

end
