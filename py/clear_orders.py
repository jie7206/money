# -*- coding: utf-8 -*-
from HuobiServices import *
import sys
import json

if __name__ == '__main__':
    symbol = sys.argv[1].split('=')[1]
    json.dump(cancel_open_orders(ACCOUNT_ID, symbol), sys.stdout)
