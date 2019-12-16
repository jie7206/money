# -*- coding: utf-8 -*-
from HuobiServices import *
from update_all import *
from update_assets import *
from deal_records import *
from open_orders import *


def fees_rate():
    return 1-0.002*0.8


def get_price_now():
    try:
        return float(get_kline('btcusdt', '1min', 1)['data'][0]['close'])
    except:
        data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'BTC'")
        return round(1/float(data[0][0]), 2)


def usd_to_cny():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'CNY'")
    return round(data[0][0], 4)


def place_new_order(price, amount, deal_type):
    try:
        root = send_order(amount, "api", 'btcusdt', deal_type, price)
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
                return float(item['balance'])
                break
    except:
        return '0'


def get_trade_btc():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'btc' and item['type'] == 'trade':
                return float(item['balance'])
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


def place_order_process(test_price, price_now, amount, deal_type, ftext, time_line, u2c):
    if test_price == 0:
        str = place_new_order(price_now, "%.6f" % amount, deal_type)
        print(str)
        ftext += str+'\n'
        time.sleep(30)
        str = "%i Deal Records added" % update_huobi_deal_records(time_line)
        print(str)
        ftext += str+'\n'
        str = "%i Open Orders added" % update_open_orders()
        print(str)
        ftext += str+'\n'
        if deal_type == 'sell-limit':
            clear_deal_records()
            update_time_lime()
            str = "Profit Earned: %.2f and All Deal Records Cleared" % profit_now
            print(str)
            ftext += str+'\n'
    else:
        if deal_type == 'sell-limit':
            sim_profit_cny = (btc_total_value(price_now) - btc_total_cost())*u2c
            str = "Sim Profit: %.2f CNY" % sim_profit_cny
            print(str)
            ftext += str+'\n'
        str = "Sim Order Price: %.2f, Amount: %.6f, Type: %s" % (price_now, amount, deal_type)
        print(str)
        ftext += str+'\n'
    trade_usdt = float(get_trade_usdt())
    str = "USDT Now: %.4f (%.2f CNY)" % (
        trade_usdt, trade_usdt*u2c)
    print(str)
    ftext += str+'\n'
    trade_btc = float(get_trade_btc())
    str = "BTC Now: %.8f (%.2f CNY) Ave: %.2f" % (
        trade_btc, trade_btc*price_now*u2c, btc_ave_cost())
    print(str)
    ftext += str+'\n'
    str = "%i Huobi Assets Updated, Process Execute Completed" % update_all_huobi_assets()
    print(str)
    ftext += str+'\n'
    if trade_btc > target_amount:
        str = "Already reach target amount, Invest PAUSE!"
        print(str)
        ftext += str+'\n'
    return ftext


def btc_total_cost():
    return btc_ave_cost()*get_trade_btc()


def btc_total_value(price):
    return price*get_trade_btc()*fees_rate()


def profit_cny_now(price_now, u2c):
    if get_trade_btc() > 0.0001:
        return round((btc_total_value(price_now)-btc_total_cost())*u2c, 2)
    else:
        return 0


def clear_deal_records():
    sql = "DELETE FROM deal_records"
    CONN.execute(sql)
    CONN.commit()


def update_time_lime():
    dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S").split(' ')
    date_str = dt[0]
    time_str = dt[1]
    new_str = ''
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[8] = date_str
            arr[9] = time_str
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def exe_auto_invest(every, below_price, bottom_price, ori_usdt, factor, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny):
    fname = 'auto_invest_log.txt'
    with open(fname, 'a') as fobj:
        ftext = '#############################################################\n'
        now = datetime.now()
        str = "%s Invest Between: %.2f ~ %.2f" % (get_now(), bottom_price, below_price)
        print(str)
        ftext += str+'\n'
        if test_price == 0:
            str = "%i Digital Prices updated" % update_prices()
            print(str)
            ftext += str+'\n'
        if test_price < 0:
            str = "Get stop command, process terminated! bye~"
            print(str)
            ftext += str+'\n'
            fobj.write(ftext)
            return 0
        trade_btc = float(get_trade_btc())
        if trade_btc < target_amount:
            target_price = float(below_price)
            price_now = float(get_price_now())
            mode = 'Now'
            if test_price > 0:
                str = "BTC Price Now: %.2f" % price_now
                print(str)
                ftext += str+'\n'
                price_now = test_price
                mode = 'TEST'
            if price_now > 0:
                str = "BTC Price %s: %.2f, Every %i Sec" % (mode, price_now, every)
                print(str)
                ftext += str+'\n'
                u2c = usd_to_cny()
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
                        usdt = round(usdt, 2)
                        amount = usdt/price_now
                        remain_hours = float(trade_usdt/usdt*every/3600)
                        delta_hours = timedelta(hours=remain_hours)
                        empty_usdt_time = to_t(now + delta_hours)
                        str = "Total USDT: %.4f USDT (%.2f CNY)" % (trade_usdt, trade_usdt*u2c)
                        print(str)
                        ftext += str+'\n'
                        str = "Invest Cost: %.4f USDT (%.2f CNY)" % (usdt, usdt*u2c)
                        print(str)
                        ftext += str+'\n'
                        str = "Buy Amount: %.6f BTC (%.2f CNY)" % (amount, amount*price_now*u2c)
                        print(str)
                        ftext += str+'\n'
                        str = "Remain Invest Hours: %.2f Hours" % remain_hours
                        print(str)
                        ftext += str+'\n'
                        str = "Empty USDT Time: " + empty_usdt_time
                        print(str)
                        ftext += str+'\n'
                        ftext = place_order_process(
                            test_price, price_now, amount, 'buy-limit', ftext, time_line, u2c)
                        fobj.write(ftext)
                        return 1
                    else:
                        str = "Run out of USDT or Price < %.2f, wait to continue..." % bottom
                        print(str)
                        ftext += str+'\n'
                        fobj.write(ftext)
                        return 1
                else:
                    str = "Price > %.2f, check if profit > %.2f then sell..." % (
                        target_price, profit_cny)
                    print(str)
                    ftext += str+'\n'
                    profit_now = profit_cny_now(price_now, u2c)
                    if profit_now > profit_cny:
                        ftext = place_order_process(
                            test_price, price_now, get_trade_btc(), 'sell-limit', ftext, time_line, u2c)
                    else:
                        str = "Profit Now: %.2f is not greater than %.2f, sorry!" % (
                            profit_now, profit_cny)
                        print(str)
                        ftext += str+'\n'
                    fobj.write(ftext)
                    return 1
            else:
                str = "Can't get price, wait %i seconds for next operate" % every
                print(str)
                ftext += str+'\n'
                fobj.write(ftext)
                return 1
        else:
            str = "Already reach target amount, Invest PAUSE!"
            print(str)
            ftext += str+'\n'
            fobj.write(ftext)
            return 1


if __name__ == '__main__':
    while True:
        try:
            with open(PARAMS, 'r') as fread:
                every, below_price, bottom_price, ori_usdt, factor, target_amount, min_usdt, max_rate, deal_date, deal_time, test_price, profit_cny = fread.read().strip().split(' ')
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
                profit_cny = float(profit_cny)
                code = exe_auto_invest(every, below_price, bottom_price, ori_usdt,
                                       factor, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny)
                if code == 0:
                    break
                for remaining in range(every, 0, -1):
                    sys.stdout.write("\r")
                    sys.stdout.write("Please wait {:2d} seconds for next operate".format(remaining))
                    sys.stdout.flush()
                    time.sleep(1)
                sys.stdout.write("\r                                                      \n")
        except:
            time.sleep(30)
