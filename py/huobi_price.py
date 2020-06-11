# -*- coding: utf-8 -*-
from HuobiServices import *
from websocket import create_connection
import sys
import json
import gzip
import time


def get_huobi_price(symbol='btcusdt', period='15min', size=200):
    root = get_kline(symbol, period, size)
    if root['status'] == 'ok':
        return root


def get_socket_huobi_price(from_time, to_time, symbol='btcusdt', period='60min'):
    while(1):
        try:
            ws = create_connection("wss://api.huobi.pro/ws")
            break
        except:
            time.sleep(2)
    # 订阅 KLine 一次性请求数据
    trade_str = """{"req": "market.%s.kline.%s","id": "id1","from":%i,"to":%i}""" % (symbol,period,from_time,to_time)
    ws.send(trade_str)
    compress_data = ws.recv()
    response = gzip.decompress(compress_data).decode('utf-8')
    return json.loads(response)


if __name__ == '__main__':
    symbol = sys.argv[1].split('=')[1]
    period = sys.argv[2].split('=')[1]
    size = sys.argv[3].split('=')[1]
    from_time = sys.argv[4].split('=')[1]
    to_time = sys.argv[5].split('=')[1]
    if from_time != '0' and to_time != '0':
        json.dump(get_socket_huobi_price(int(from_time), int(to_time), symbol, period), sys.stdout)
    else:
        json.dump(get_huobi_price(symbol, period, size), sys.stdout)
