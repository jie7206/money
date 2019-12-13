# -*- coding: utf-8 -*-
from HuobiServices import *


# 更新火币所有账号的资产余额
def update_all_huobi_assets():
    count = 0
    amounts = {'usdt': 0, 'btc': 0, 'atom': 0, 'ht': 0}
    # 1.读取火币资产数据
    for item in get_balance(ACCOUNT_ID)['data']['list']:
        for currency in [s[0] for s in SYMBOLS]:
            if item['currency'] == currency:
                amounts[currency] += float(item['balance'])
    # 2.逐笔更新火币相关资产
    for key in amounts:
        keyword = '17099311026: '+key.upper()
        sql = "UPDATE properties SET amount = %.8f, updated_at = '%s' WHERE name LIKE '%%%%%s%%%%'" % \
              (amounts[key], get_now(), keyword)
        CONN.execute(sql)
        CONN.commit()
        count += 1
    return count


if __name__ == '__main__':
    try:
        print("%i 种数字资产余额已更新" % update_all_huobi_assets(), sys.stdout)
    except:
        print("网路不顺畅，请稍后再试！", sys.stdout)
