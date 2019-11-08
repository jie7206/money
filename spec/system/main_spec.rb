require 'rails_helper'

RSpec.describe '系统测试(Main)', type: :system do

  describe '登入与登出功能测试' do

    specify '正确输入PIN码之后跳转回根目录' do
      visit root_path
      expect(current_path).to eq login_path
      expect(page).to have_selector '#pincode'
      fill_in 'pincode', with: $pincode
      find('#login').click
      expect(current_path).to eq root_path
    end

    specify 'PIN码输入错误之后会提示错误讯息' do
      visit root_path
      fill_in 'pincode', with: $pincode*2
      find('#login').click
      expect(page).to have_content $login_error_message
    end

    specify '点击页面的登出链接即可安全登出' do
      visit login_path
      fill_in 'pincode', with: $pincode
      find('#login').click
      within '#site_nav' do
        find('#logout').click
      end
      visit root_path
      expect(current_path).to eq login_path
    end

    specify '#118[系统层]以管理员密码能正常登入和登出系统' do
      visit login_path
      fill_in 'pincode', with: "#{$pincode}:#{$admincode}"
      find('#login').click
      expect(current_path).to eq root_path
      within '#site_nav' do
        find('#logout').click
      end
      visit root_path
      expect(current_path).to eq login_path
    end

  end

end
