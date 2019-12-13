# -*- coding: utf-8 -*-
from HuobiServices import *


# 更新未成交订单
def update_open_orders():
    count = 0
    sql = "DELETE FROM open_orders"
    CONN.execute(sql)
    CONN.commit()
    for data in open_orders(ACCOUNT_ID, 'btcusdt')['data']:
        order_id = data['id']
        symbol = data['symbol']
        amount = float(data['amount'])
        price = float(data['price'])
        order_type = data['type']
        created_at = db_time(data['created-at'])
        sql = "INSERT INTO open_orders (order_id, symbol, amount, price, order_type, created_at, updated_at) \
               VALUES ('%s', '%s', %f, %f, '%s', '%s', '%s')" \
                % (order_id, symbol, amount, price, order_type, created_at, created_at)
        CONN.execute(sql)
        CONN.commit()
        count += 1
    return count


if __name__ == '__main__':
    try:
        print("新增%i笔下单记录！" % update_open_orders(), sys.stdout)
    except:
        print("网路不顺畅，请稍后再试！", sys.stdout)
