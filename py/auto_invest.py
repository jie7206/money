# -*- coding: utf-8 -*-
from HuobiServices import *
from update_all import *
import sys
import time
import datetime


def place_new_order(price, amount):
    try:
        root = send_order(amount, "api", 'btcusdt', 'buy-limit', price)
        if root["status"] == "ok":
            return "Send Order(%s) successfully" % root["data"]
    except:
        return 'Some error happened'


def clear_orders():
    try:
        root = cancel_open_orders(ACCOUNT_ID, 'btcusdt')
        if root["status"] == "ok":
            return 'All open orders cleared'
    except:
        return 'Some error happened'


def get_trade_usdt():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'usdt' and item['type'] == 'trade':
                return item['balance']
                break
    except:
        return '0'


def get_trade_btc():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'btc' and item['type'] == 'trade':
                return item['balance']
                break
    except:
        return '0'


def exe_auto_invest(every, below_price, bottom_price, ori_usdt, factor, test_price=0):
    now = datetime.datetime.now()
    u2c = 7.02
    min_usdt = 1.5
    max_rate = 0.05
    size = 60
    factor = float(factor)
    test_price = float(test_price)
    print("%s Start: " % get_now())
    print("%i Digital Prices updated" % update_prices())
    print(clear_orders())
    target = float(below_price)
    price_now, ave_price = get_btc_price(size)
    if test_price > 0:
        price_now = test_price
    if price_now > 0:
        print("BTC Price: %.2f with MA%i: %.2f" % (price_now, size, ave_price))
        if price_now <= target:
            ori_usdt = float(ori_usdt)
            trade_usdt = float(get_trade_usdt())
            trade_btc = float(get_trade_btc())
            bottom = float(bottom_price)
            max_usdt = ori_usdt*max_rate
            if trade_usdt > min_usdt and price_now - bottom > 0:
                usdt = (ori_usdt/(((price_now-bottom)/100)**2))*factor
                if usdt < min_usdt:
                    usdt = min_usdt
                if usdt > max_usdt:
                    usdt = max_usdt
                    if usdt > trade_usdt:  # Not enough money to buy
                        usdt = trade_usdt
                amount = usdt/price_now
                remain_hours = float(trade_usdt/usdt*every/3600)
                delta_hours = datetime.timedelta(hours=remain_hours)
                empty_usdt_time = to_t(now + delta_hours)
                print("Total USDT: %.4f USDT (%.2f CNY)" % (trade_usdt, trade_usdt*u2c))
                print("Invest Cost: %.4f USDT (%.2f CNY)" % (usdt, usdt*u2c))
                print("Buy Amount: %.6f BTC (%.2f CNY)" % (amount, amount*price_now*u2c))
                print("Remain Invest Hours: %.2f Hours" % remain_hours)
                print("Empty USDT Time: ", empty_usdt_time)
                print("Total BTC: %.8f BTC (%.2f CNY)" % (trade_btc, trade_btc*price_now*u2c))
                print(place_new_order(price_now, "%.6f" % amount))
                time.sleep(5)
                print("%i Assets Updated" % update_all_huobi_assets())
                print("%i Deal Records added" % update_huobi_deal_records())
        else:
            print("Price greater than %2.f, wait %i seconds for next operate" % (target, every))
    else:
        print("Can't get price, wait %i seconds for next operate" % every)


if __name__ == '__main__':
    every = int(sys.argv[1])
    below_price = float(sys.argv[2])
    bottom_price = float(sys.argv[3])
    ori_usdt = float(sys.argv[4])
    factor = float(sys.argv[5])
    test_price = float(sys.argv[6])
    while True:
        try:
            exe_auto_invest(every, below_price, bottom_price, ori_usdt, factor, test_price)
            for remaining in range(every, 0, -1):
                sys.stdout.write("\r")
                sys.stdout.write("Please wait {:2d} seconds for next operate".format(remaining))
                sys.stdout.flush()
                time.sleep(1)
            sys.stdout.write("\r                                                      \n")
        except:
            time.sleep(every)
