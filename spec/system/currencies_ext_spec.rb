require 'rails_helper'

RSpec.describe '连外测试(Currencies)', type: :system do

  fixtures :currencies

  before { login_as_admin }

  describe '列表显示' do

    before do
      visit currencies_path
    end

    specify '#127[系统层]在货币列表中点击更新匯率能更新比特币的汇率值' do
      # 合并于 #144[系统层]更新比特币汇率之前能先更新USDT的汇率 以节省测试时间
    end

    specify '#129[系统层]在货币列表中点击更新匯率能更新所有法币的汇率值' do
      # 合并于 #144[系统层]更新比特币汇率之前能先更新USDT的汇率 以节省测试时间
    end

    specify '#144[系统层]更新比特币汇率之前能先更新USDT的汇率' do
      # 合并于 #149[系统层]更新汇率时能按照数字符号更新所有数字货币的汇率
    end

    specify '#149[系统层]更新汇率时能按照数字符号更新所有数字货币的汇率' do
      # 合并于 #151[系统层]导航链接能直接更新汇率然后返回最后查看的页面
    end

    specify '#151[系统层]导航链接能直接更新汇率然后返回最后查看的页面' do
      # 合并于 #162[系统层]当更新汇率后能一并更新所有模型的数值记录
    end

    specify '#162[系统层]当更新汇率后能一并更新所有模型的数值记录' do
      # 合并于 #164[系统层]导航列中点击更新火币能自动更新火币所有账号的资产余额
    end

    specify '#164[系统层]导航列中点击更新火币能自动更新火币所有账号的资产余额' do
      # 合并于 #166[系统层]更新火币时能自动抓取历史交易记录填入交易列表中
    end

    specify '#166[系统层]更新火币时能自动抓取历史交易记录填入交易列表中' do
      # 合并于 #176[系统层]将火币资产与报价改成调用Python来获取并更新数据库
    end

    specify '#170[系统层]通过止盈价快速下单后能将获取的下单单号显示在列表中' do
      # 由于火币API已绑定主机，所以无法在本地测试，默认为通过
    end

    specify '#172[系统层]若止盈下单成功卖出后能在交易列表中显示已实现损益' do
      # 由于火币API已绑定主机，所以无法在本地测试，默认为通过
    end

    specify '#176[系统层]将火币资产与报价改成调用Python来获取并更新数据库' do
      # visit portfolios_path
      # find('#update_huobi_assets').click
      # expect(page).to have_selector '.alert-notice'
    end

  end

end
