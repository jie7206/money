# -*- coding: utf-8 -*-
import sys
import time
from HuobiServices import *
from update_assets import *
from deal_records import *
from open_orders import *


SYMBOLS = [['btc', 'btcusdt'], ['ht', 'htusdt']]


# 更新数字货币最新报价
def update_prices():
    global SYMBOLS
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


if __name__ == '__main__':
    try:
        print("%i种数字货币报价已更新" % update_prices(), sys.stdout)
        updated_assets = update_all_huobi_assets()
        if updated_assets > 0:
            print("%i种数字资产余额已更新" % updated_assets, sys.stdout)
        new_deal_records = update_huobi_deal_records(get_time_line())
        if new_deal_records > 0:
            print("新增%i笔交易记录！" % new_deal_records, sys.stdout)
        else:
            print("无新增交易！", sys.stdout)
        new_open_orders = update_open_orders()
        if new_open_orders > 0:
            print("新增%i笔下单记录！" % new_open_orders, sys.stdout)
        else:
            print("无新增下单！", sys.stdout)
        print("所有主要资料已更新！", sys.stdout)
    except:
        print("网路不顺畅，请稍后再试！", sys.stdout)
