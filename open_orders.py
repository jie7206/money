# -*- coding: utf-8 -*-
import sys
import time
import json
import sqlite3
from HuobiServices import *
from datetime import datetime


# 查询未成交订单
def get_open_orders():
    return open_orders(ACCOUNT_ID, 'btcusdt', size=20)


if __name__ == '__main__':
    try:
        # print(get_open_orders(), sys.stdout)  # 查询未成交订单
        json.dump(get_open_orders(), sys.stdout)
    except:
        print("网路不顺畅，请稍后再试！", sys.stdout)
