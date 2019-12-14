# -*- coding: utf-8 -*-
from HuobiServices import *
from update_all import *


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
    if len(rows) > 0:
        sum_price = sum_amount = 0
        for row in rows:
            price = row[0]
            amount = row[1]
            fees = row[2]
            amount = amount - fees
            sum_price += price*amount
            sum_amount += amount
        return round(sum_price/sum_amount, 2)
    else:
        return 0


def exe_auto_invest(every, below_price, bottom_price, ori_usdt, factor, target_amount, min_usdt, max_rate, time_line, test_price=0):
    fname = 'auto_invest_log.txt'
    ftext = '############################################################\n'
    with open(fname, 'a') as fobj:
        now = datetime.now()
        str1 = "%s Invest Between: %.2f ~ %.2f" % (get_now(), bottom_price, below_price)
        print(str1)
        ftext += str1+'\n'
        if test_price == 0:
            str2 = "%i Digital Prices updated" % update_prices()
            print(str2)
            ftext += str2+'\n'
        if test_price < 0:
            str18 = "Get stop command, process terminated! bye~"
            print(str18)
            ftext += str18+'\n'
            fobj.write(ftext)
            return 0
        trade_btc = float(get_trade_btc())
        if trade_btc < target_amount:
            target_price = float(below_price)
            price_now = float(get_price_now())
            mode = 'Now'
            if test_price > 0:
                price_now = test_price
                mode = 'TEST'
            if price_now > 0:
                str3 = "BTC Price %s: %.2f, Every %i Sec" % (mode, price_now, every)
                print(str3)
                ftext += str3+'\n'
                if price_now <= target_price:
                    u2c = usd_to_cny()
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
                        usdt = round(usdt, 2)
                        amount = usdt/price_now
                        remain_hours = float(trade_usdt/usdt*every/3600)
                        delta_hours = timedelta(hours=remain_hours)
                        empty_usdt_time = to_t(now + delta_hours)
                        str4 = "Total USDT: %.4f USDT (%.2f CNY)" % (trade_usdt, trade_usdt*u2c)
                        str5 = "Invest Cost: %.4f USDT (%.2f CNY)" % (usdt, usdt*u2c)
                        str6 = "Buy Amount: %.6f BTC (%.2f CNY)" % (amount, amount*price_now*u2c)
                        str7 = "Remain Invest Hours: %.2f Hours" % remain_hours
                        str8 = "Empty USDT Time: " + empty_usdt_time
                        print(str4)
                        print(str5)
                        print(str6)
                        print(str7)
                        print(str8)
                        ftext += str4+'\n'
                        ftext += str5+'\n'
                        ftext += str6+'\n'
                        ftext += str7+'\n'
                        ftext += str8+'\n'
                        if test_price == 0:
                            str9 = place_new_order(price_now, "%.6f" % amount)
                            print(str9)
                            ftext += str9+'\n'
                            time.sleep(20)
                            deal_records = update_huobi_deal_records(time_line)
                            if deal_records > 0:
                                str10 = "%i Deal Records added" % deal_records
                                str11 = "%i Huobi Assets Updated" % update_all_huobi_assets()
                                print(str10)
                                print(str11)
                                ftext += str10+'\n'
                                ftext += str11+'\n'
                            else:
                                new_open_orders = update_open_orders()
                                if new_open_orders > 0:
                                    str16 = "%i Open Orders added" % new_open_orders
                                    print(str16)
                                    ftext += str16+'\n'
                        trade_btc = float(get_trade_btc())
                        str12 = "BTC Now: %.8f (%.2f CNY) Ave: %.2f" % (
                            trade_btc, trade_btc*price_now*u2c, btc_ave_cost())
                        print(str12)
                        ftext += str12+'\n'
                        if trade_btc < target_amount:
                            fobj.write(ftext)
                            return 1
                        else:
                            str13 = "Already reach target amount, Invest PAUSE!"
                            print(str13)
                            ftext += str13+'\n'
                            fobj.write(ftext)
                            return 1
                    else:
                        str17 = "Run out of USDT, Recharge to continue..."
                        print(str17)
                        ftext += str17+'\n'
                        fobj.write(ftext)
                        return 1
                else:
                    str14 = "Price greater than %2.f, wait %i seconds for next operate" % (
                        target_price, every)
                    print(str14)
                    ftext += str14+'\n'
                    fobj.write(ftext)
                    return 1
            else:
                str15 = "Can't get price, wait %i seconds for next operate" % every
                print(str15)
                ftext += str15+'\n'
                fobj.write(ftext)
                return 1
        else:
            str13 = "Already reach target amount, Invest PAUSE!"
            print(str13)
            ftext += str13+'\n'
            fobj.write(ftext)
            return 1


if __name__ == '__main__':
    while True:
        try:
            with open(PARAMS, 'r') as fread:
                every, below_price, bottom_price, ori_usdt, factor, target_amount, min_usdt, max_rate, deal_date, deal_time, test_price = fread.read().strip().split(' ')
                every = int(every)
                below_price = float(below_price)
                bottom_price = float(bottom_price)
                ori_usdt = float(ori_usdt)
                factor = float(factor)
                target_amount = float(target_amount)
                min_usdt = float(min_usdt)  # 1.5
                max_rate = float(max_rate)  # 0.05
                time_line = deal_date+' '+deal_time
                test_price = float(test_price)
                code = exe_auto_invest(every, below_price, bottom_price, ori_usdt,
                                       factor, target_amount, min_usdt, max_rate, time_line, test_price)
                if code == 0:
                    break
                for remaining in range(every, 0, -1):
                    sys.stdout.write("\r")
                    sys.stdout.write("Please wait {:2d} seconds for next operate".format(remaining))
                    sys.stdout.flush()
                    time.sleep(1)
                sys.stdout.write("\r                                                      \n")
        except:
            time.sleep(60)
