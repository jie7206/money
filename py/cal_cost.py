# -*- coding: utf-8 -*-
from update_all import *


def exe_cal_cost():
    rows = select_db("SELECT price, amount FROM deal_records")
    sum_price = sum_amount = 0
    for row in rows:
        price = row[0]
        amount = row[1]
        sum_price += price*amount
        sum_amount += amount
    return round(sum_price/sum_amount, 2)


if __name__ == '__main__':
    try:
        return exe_cal_cost()
    except:
        return 0
