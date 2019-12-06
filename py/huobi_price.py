# -*- coding: utf-8 -*-
from HuobiServices import *
import sys
import json


def get_huobi_price(symbol='btcusdt', period='15min', size=200):
    root = get_kline(symbol, period, size)
    if root['status'] == 'ok':
        return root


if __name__ == '__main__':
    symbol = sys.argv[1].split('=')[1]
    period = sys.argv[2].split('=')[1]
    size = sys.argv[3].split('=')[1]
    json.dump(get_huobi_price(symbol, period, size), sys.stdout)
