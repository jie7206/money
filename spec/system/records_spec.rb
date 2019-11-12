require 'rails_helper'

RSpec.describe '系统测试(Records)', type: :system do

  describe '一般登入' do

    before { login_as_guest }

    specify '#161[系统层]访问资产负债表时能自动写入资产净值到数值记录表' do
      record = create(:record,:net,updated_at: 1.day.ago)
      ori_updated_at = record.updated_at
      visit properties_path
      expect(record.reload.updated_at).not_to eq ori_updated_at
    end

  end

end
