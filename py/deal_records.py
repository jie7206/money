# -*- coding: utf-8 -*-
import sys
import time
import json
import sqlite3
from HuobiServices import *


# 更新买入比特币的交易记录
def update_huobi_deal_records(time_line='2019-12-12 12:00:00'):
    count = 0
    for deal_type in ['buy-limit', 'buy-market']:
        for data in orders_matchresults('btcusdt', deal_type)['data']:
            data_id = int(data['id'])
            sql = "SELECT id FROM deal_records WHERE data_id = %i" % data_id
            result = CONN.execute(sql)
            if not len(result.fetchall()) == 1:
                price = float(data['price'])
                amount = float(data['filled-amount'])
                fees = float(data['filled-fees'])
                earn_limit = float((fees*price+price*amount*0.002)*7.1)
                created_at = db_time(data['created-at'])
                if created_at > time_line:
                    sql = "INSERT INTO deal_records (account, data_id, symbol, deal_type, price, amount, fees, \
                            earn_limit, loss_limit, created_at, updated_at) VALUES ('170', %i, 'btcusdt', '%s', %f, %f, %f, %.4f, 0, '%s', '%s')" \
                            % (data_id, deal_type, price, amount, fees, earn_limit, created_at, created_at)
                    CONN.execute(sql)
                    CONN.commit()
                    count += 1
    return count


if __name__ == '__main__':
    try:
        new_deal_records = update_huobi_deal_records(get_time_line())
        if new_deal_records > 0:
            print("新增%i笔交易记录！" % new_deal_records, sys.stdout)
        else:
            print("无新增交易！", sys.stdout)
    except:
        print("网路不顺畅，请稍后再试！", sys.stdout)
