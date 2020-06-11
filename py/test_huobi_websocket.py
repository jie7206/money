# !/usr/bin/env python
# -*- coding: utf-8 -*-
# author: luhx
# https://pypi.org/project/websocket-client/
# pip install websocket-client
# 火币数据调试， 感觉这个websocket客户端很好用

from websocket import create_connection
import gzip
import time

if __name__ == '__main__':
    while(1):
        try:
            ws = create_connection("wss://api.huobi.pro/ws")
            break
        except:
            print('connect ws error,retry...')
            time.sleep(5)

    # 订阅 KLine 数据
    # tradeStr="""{"sub": "market.btcusdt.kline.1min","id": "id1"}"""
    tradeStr="""{"req": "market.btcusdt.kline.30min","id": "id1","from":1546272000,"to":1546704000}"""

    ws.send(tradeStr)
    # while(1):
    #     compressData=ws.recv()
    #     result=gzip.decompress(compressData).decode('utf-8')
    #     if result[:7] == '{"ping"':
    #         ts=result[8:21]
    #         pong='{"pong":'+ts+'}'
    #         ws.send(pong)
    #         ws.send(tradeStr)
    #     else:
    #         print(result)
    compressData=ws.recv()
    result=gzip.decompress(compressData).decode('utf-8')
    filename = "btc_prices.txt"
    with open(filename, 'w+') as f:
        f.write(result)
        print("BTC Prices write to %s Success!" % filename)
