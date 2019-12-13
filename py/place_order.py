# -*- coding: utf-8 -*-
from HuobiServices import *


def new_order(symbol, deal_type, price, amount):
    return send_order(amount, "api", symbol, deal_type, price)


if __name__ == '__main__':
    _symbol = sys.argv[1].split('=')[1]
    _type = sys.argv[2].split('=')[1]
    _price = sys.argv[3].split('=')[1]
    _amount = sys.argv[4].split('=')[1]
    json.dump(new_order(_symbol, _type, _price, _amount), sys.stdout)
