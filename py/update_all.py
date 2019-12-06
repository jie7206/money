# -*- coding: utf-8 -*-
import sys
import time
import sqlite3
from HuobiServices import *
from deal_records import *
from open_orders import *


SYMBOLS = [['usdt', 'usdthusd'], ['btc', 'btcusdt'], ['atom', 'atomusdt']]
CONN = sqlite3.connect(DB)


# 更新數字貨幣最新报价
def update_prices():
    for symbol in [s[1] for s in SYMBOLS]:
        price = float(get_kline(symbol, '1min', 1)['data'][0]['close'])
        sql = "UPDATE currencies SET exchange_rate = %.10f, updated_at = '%s' WHERE symbol = '%s'" % \
              (1.0/price, get_now(), symbol)
        CONN.execute(sql)
        CONN.commit()
        print("%s 价格更新为 %.2f" % (symbol.upper(), price), sys.stdout)


# 更新火币所有账号的资产余额
def update_all_huobi_assets():
    amounts = {'usdt': 0, 'btc': 0, 'atom': 0}
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
        print("%s 资产更新为 %.4f" % (key.upper(), amounts[key]), sys.stdout)


if __name__ == '__main__':
    try:
        update_prices()  # 更新數字貨幣最新报价
        update_all_huobi_assets()  # 更新火币所有账号的资产余额
        update_huobi_deal_records()  # 更新买入比特币的交易记录
        update_open_orders()  # 更新未成交订单
        print("所有主要资料已更新！", sys.stdout)
    except:
        print("网路不顺畅，请稍后再试！", sys.stdout)
    CONN.close()
