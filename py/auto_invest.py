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


def get_remain_usdt():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'usdt' and item['type'] == 'trade':
                return item['balance']
                break
    except:
        return '0'


def exe_auto_invest(every, below_price, bottom_price):
    now = datetime.datetime.now()
    u2c = 7.02
    min_usdt = 1.5
    max_rate = 0.1
    size = 60
    print("%s Start: " % get_now())
    target = float(below_price)
    price_now, ave_price = get_btc_price(size)
    if price_now > 0:
        print("BTC Price: %.2f with MA%i: %.2f" % (price_now, size, ave_price))
        if price_now <= target:
            remain_usdt = float(get_remain_usdt())
            bottom = float(bottom_price)
            max_usdt = remain_usdt*max_rate
            if remain_usdt > min_usdt and price_now - bottom > 0:
                usdt = remain_usdt/(((price_now-bottom)/100)**2)
                if usdt < min_usdt:
                    usdt = min_usdt
                if usdt > max_usdt:
                    usdt = max_usdt
                amount = usdt/price_now
                remain_hours = float(remain_usdt/usdt*every/3600)
                delta_hours = datetime.timedelta(hours=remain_hours)
                empty_usdt_time = now + delta_hours
                print("Total USDT: %.4f USDT (%.2f CNY)" % (remain_usdt, remain_usdt*u2c))
                print("Invest Cost: %.4f USDT (%.2f CNY)" % (usdt, usdt*u2c))
                print("Buy Amount: %.6f BTC" % amount)
                print("Remain Invest Hours: %.2f H" % remain_hours)
                print("Empty USDT Time: ", empty_usdt_time)
                print(clear_orders())
                print(place_new_order(price_now, "%.6f" % amount))
                print("%i Assets Updated" % update_all_huobi_assets())
                print("%i Deal Records added" % update_huobi_deal_records())
                print("%i Digital Prices updated" % update_prices())
        else:
            print("Price greater than %2.f, wait %i seconds for next operate" % (target, every))
    else:
        print("Can't get price, wait %i seconds for next operate" % every)


if __name__ == '__main__':
    every = int(sys.argv[1])
    below_price = float(sys.argv[2])
    bottom_price = float(sys.argv[3])
    while True:
        try:
            exe_auto_invest(every, below_price, bottom_price)
            for remaining in range(every, 0, -1):
                sys.stdout.write("\r")
                sys.stdout.write("Please wait {:2d} seconds for next operate".format(remaining))
                sys.stdout.flush()
                time.sleep(1)
            sys.stdout.write("\r                                                      \n")
        except:
            time.sleep(every)
