# -*- coding: utf-8 -*-
from HuobiServices import *
import sys
import json

result = ""

if __name__ == '__main__':
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if (item['currency'] == 'usdt' and item['type'] == 'trade') or \
                    (item['currency'] == 'btc' and item['type'] == 'trade'):
                result += item['balance'] + ','
                if result.index(',') != result.rindex(','):
                    break
        print(result, sys.stdout)
    except:
        print('0', sys.stdout)

