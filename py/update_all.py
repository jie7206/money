# -*- coding: utf-8 -*-
import sys
import time
import sqlite3
from HuobiServices import *
from deal_records import *
from open_orders import *


SYMBOLS = [['usdt', 'usdthusd'], ['btc', 'btcusdt'], ['atom', 'atomusdt'], ['ht', 'htusdt']]
CONN = sqlite3.connect(DB)


# 更新数字货币最新报价
def update_prices():
    count = 0
    for symbol in [s[1] for s in SYMBOLS]:
        try:
            price = float(get_kline(symbol, '1min', 1)['data'][0]['close'])
            if price > 0:
                sql = "UPDATE currencies SET exchange_rate = %.10f, updated_at = '%s' WHERE symbol = '%s'" % \
                      (1.0/price, get_now(), symbol)
                CONN.execute(sql)
                CONN.commit()
                count += 1
        except:
            return count
    return count


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
        print("%i 种数字货币报价已更新" % update_prices(), sys.stdout)
        print("%i 种数字资产余额已更新" % update_all_huobi_assets(), sys.stdout)
        new_deal_records = update_huobi_deal_records()
        if new_deal_records > 0:
            print("新增 %i笔交易记录！" % new_deal_records, sys.stdout)
        else:
            print("无新增交易！", sys.stdout)
        new_open_orders = update_open_orders()
        if new_open_orders > 0:
            print("新增 %i笔下单记录！" % new_open_orders, sys.stdout)
        else:
            print("无新增下单！", sys.stdout)
        print("所有主要资料已更新！", sys.stdout)
    except:
        print("网路不顺畅，请稍后再试！", sys.stdout)
    CONN.close()
