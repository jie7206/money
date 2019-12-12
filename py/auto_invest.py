# -*- coding: utf-8 -*-
from HuobiServices import *
from update_all import *
import sys
import time
import datetime


def get_price_now():
    try:
        return float(get_kline('btcusdt', '1min', 1)['data'][0]['close'])
    except:
        data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'BTC'")
        return round(1/float(data[0][0]), 2)


def usd_to_cny():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'CNY'")
    return round(data[0][0], 4)


def place_new_order(price, amount):
    try:
        root = send_order(amount, "api", 'btcusdt', 'buy-limit', price)
        if root["status"] == "ok":
            return "Send Order(%s) successfully" % root["data"]
        else:
            return root
    except:
        return 'Some unknow error happened!'


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


def btc_ave_cost():
    rows = select_db("SELECT price, amount, fees FROM deal_records")
    sum_price = sum_amount = 0
    for row in rows:
        price = row[0]
        amount = row[1]
        fees = row[2]
        amount = amount - fees
        sum_price += price*amount
        sum_amount += amount
    return round(sum_price/sum_amount, 2)


def exe_auto_invest(every, below_price, bottom_price, ori_usdt, factor, target_amount, test_price=0):
    min_usdt = 2.0
    max_rate = 0.05
    now = datetime.datetime.now()
    u2c = usd_to_cny()
    print("%s Invest Between: %.2f ~ %.2f" % (get_now(), bottom_price, below_price))
    print("%i Digital Prices updated" % update_prices())
    trade_btc = float(get_trade_btc())
    if trade_btc < target_amount:
        target_price = float(below_price)
        price_now = float(get_price_now())
        if test_price > 0:
            price_now = test_price
        if price_now > 0:
            print("BTC Price Now: %.2f" % price_now)
            if price_now <= target_price:
                ori_usdt = float(ori_usdt)
                trade_usdt = float(get_trade_usdt())
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
                    if not test_price > 0:
                        print(place_new_order(price_now, "%.6f" % amount))
                        time.sleep(20)
                        deal_records = update_huobi_deal_records()
                        if deal_records > 0:
                            print("%i Deal Records added" % deal_records)
                            print("%i Huobi Assets Updated" % update_all_huobi_assets())
                    trade_btc = float(get_trade_btc())
                    print("BTC Now: %.8f (%.2f CNY) Ave: %.2f" %
                          (trade_btc, trade_btc*price_now*u2c, btc_ave_cost()))
                    if trade_btc < target_amount:
                        return 1
                    else:
                        print("Already reach target amount, YA! bye~")
                        return 0
            else:
                print("Price greater than %2.f, wait %i seconds for next operate" %
                      (target_price, every))
                return 0
        else:
            print("Can't get price, wait %i seconds for next operate" % every)
            return 0
    else:
        print("Already reach target amount, YA! bye~")
        return 0


if __name__ == '__main__':
    every = int(sys.argv[1])
    below_price = float(sys.argv[2])
    bottom_price = float(sys.argv[3])
    ori_usdt = float(sys.argv[4])
    factor = float(sys.argv[5])
    target_amount = float(sys.argv[6])
    test_price = float(sys.argv[7])
    while True:
        try:
            code = exe_auto_invest(every, below_price, bottom_price, ori_usdt,
                                   factor, target_amount, test_price)
            if test_price > 0 or code == 0:
                break
            for remaining in range(every, 0, -1):
                sys.stdout.write("\r")
                sys.stdout.write("Please wait {:2d} seconds for next operate".format(remaining))
                sys.stdout.flush()
                time.sleep(1)
            sys.stdout.write("\r                                                      \n")
        except:
            time.sleep(every)
