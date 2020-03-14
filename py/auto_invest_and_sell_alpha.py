# -*- coding: utf-8 -*-
from HuobiServices import *
from update_all import *
from update_assets import *
from deal_records import *
from open_orders import *

ORDER_ID = ''


def fees_rate():
    return 1-0.002


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
    global ORDER_ID
    try:
        root = send_order(amount, "api", 'btcusdt', deal_type, price)
        if root["status"] == "ok":
            ORDER_ID = root["data"]
            return "Send Order(%s) successfully" % root["data"]
        else:
            return root
    except:
        return 'Some unknow error happened when place_new_order!'


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
    rows = select_db("SELECT price, amount, fees FROM deal_records WHERE auto_sell = 0")
    if len(rows) > 0:
        sum_price = sum_amount = 0
        for row in rows:
            price = row[0]
            amount = row[1]
            fees = row[2]
            sum_price += price*amount
            amount = amount - fees
            sum_amount += amount
        return round(sum_price/sum_amount, 2)
    else:
        return 0


def place_order_process(test_price, price_now, amount, deal_type, ftext, time_line, u2c):
    if test_price == 0:
        str = place_new_order("%.2f" % price_now, "%.6f" % amount, deal_type)
        print(str)
        ftext += str+'\n'
        time.sleep(10)
        str = "%i Deal Records added" % update_huobi_deal_records(time_line)
        print(str)
        ftext += str+'\n'
        str = "%i Open Orders added" % update_open_orders()
        print(str)
        ftext += str+'\n'
    else:
        str = "Sim Order Price: %.2f, Amount: %.6f, Type: %s" % (price_now, amount, deal_type)
        print(str)
        ftext += str+'\n'
    trade_usdt = float(get_trade_usdt())
    usdt_cny = trade_usdt*u2c
    str = "USDT Trade Now: %.4f (%.2f CNY)" % (
        trade_usdt, usdt_cny)
    print(str)
    ftext += str+'\n'
    trade_btc = float(get_trade_btc())
    btc_cny = trade_btc*price_now*u2c
    str = "BTC  Trade Now: %.8f (%.2f CNY)" % (
        trade_btc, btc_cny)
    print(str)
    ftext += str+'\n'
    profit_now = profit_cny_now(price_now, u2c)
    str = "BTC  Level Now: %.2f%%  Ave: %.2f Profit Now: %.2f CNY" % (
        btc_hold_level(price_now, u2c), btc_ave_cost(), profit_now)
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
    sql = "DELETE FROM deal_records WHERE auto_sell = 0"
    CONN.execute(sql)
    CONN.commit()


def update_time_line(time_str):
    dt = time_str.split(' ')
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


def btc_hold_level(price_now, u2c):
    amounts = {'usdt': 0, 'btc': 0}
    for item in get_balance(ACCOUNT_ID)['data']['list']:
        for currency in ['usdt', 'btc']:
            if item['currency'] == currency:
                amounts[currency] += float(item['balance'])
    btc_cny = price_now*amounts['btc']*u2c
    usdt_cny = amounts['usdt']*u2c
    return btc_cny/(btc_cny+usdt_cny)*100


def print_next_exe_time(every_sec, ftext):
    next_hours = float(every_sec/3600)
    delta_next_hours = timedelta(hours=next_hours)
    next_exe_time = to_t(datetime.now() + delta_next_hours)
    str = "Next Time: %s (%.2f M | %.2f H)" % (
        next_exe_time, every_sec/60, every_sec/3600)
    print(str)
    ftext += str+'\n'
    return ftext


def batch_sell_process(test_price, price_now, ftext, time_line, u2c, profit_cny, max_sell_count):
    global ORDER_ID
    rows = select_db(
        "SELECT id, amount-fees as amount, created_at FROM deal_records WHERE auto_sell = 0 ORDER BY created_at ASC LIMIT %i" % max_sell_count)
    if len(rows) > 0:
        ids = []
        sell_amount = 0
        count = 0
        created_at = ''
        ave_cost = btc_ave_cost()
        sell_price = round(price_now*0.9997, 2)
        for row in rows:
            id = row[0]
            amount = row[1]
            created_at = row[2]
            ids.append(id)
            sell_amount += amount
            sell_profit = (sell_price-ave_cost)*sell_amount*fees_rate()*u2c
            if sell_profit > profit_cny:
                # 提交订单
                ftext = place_order_process(test_price, sell_price,
                                            sell_amount, 'sell-limit', ftext, time_line, u2c)
                # 如果提交成功，将这些交易记录标示为已自动卖出并更新下单编号及已实现损益
                if test_price == 0 and len(ORDER_ID) > 0:
                    real_profit = round(sell_profit/len(ids), 2)
                    for id in ids:
                        sql = "UPDATE deal_records SET auto_sell = 1, order_id = '%s', real_profit = %.2f, updated_at = '%s' WHERE id = %i" % (
                            ORDER_ID, real_profit, get_now(), id)
                        CONN.execute(sql)
                        CONN.commit()
                        count += 1
                    ORDER_ID = ''
                    str = "%i Deal Records Auto Sold" % count
                    print(str)
                    ftext += str+'\n'
                    # 更新记录time_line文档
                    update_time_line(created_at)
                    str = "Time Line Updated to: %s" % created_at
                    print(str)
                    ftext += str+'\n'
                else:
                    str = "Sim Update %i Deal Records" % len(ids)
                    print(str)
                    ftext += str+'\n'
                break
        return ftext


def exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt, factor, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate):
    global ORDER_ID
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
                str = "BTC Price %s: %.2f" % (mode, price_now)
                print(str)
                ftext += str+'\n'
                u2c = usd_to_cny()
                if price_now <= target_price:
                    ori_usdt = float(ori_usdt)
                    trade_usdt = float(get_trade_usdt())
                    bottom = float(bottom_price)
                    max_usdt = ori_usdt*max_rate
                    if trade_usdt > min_usdt and price_now - bottom >= 0:
                        # Caculate USDT and Amount
                        price_diff = price_now - bottom
                        if price_now - bottom < 1:
                            price_diff = 1
                        usdt = (ori_usdt/((price_diff)/100)**2)*factor
                        if usdt < min_usdt:
                            usdt = min_usdt
                        if usdt > max_usdt:
                            usdt = max_usdt
                            if usdt > trade_usdt:  # Not enough money to buy
                                usdt = trade_usdt
                        usdt = round(usdt, 2)
                        amount = usdt/price_now
                        # Caculate New Seconds Period
                        min_sec = every_sec*min_sec_rate
                        new_sec = min_sec + every_sec*(max_sec_rate-min_sec_rate) * \
                            ((price_now-bottom_price)/(below_price-bottom_price))
                        every_sec = int(new_sec)
                        remain_hours = float(trade_usdt/usdt*every_sec/3600)
                        delta_hours = timedelta(hours=remain_hours)
                        empty_usdt_time = to_t(now + delta_hours)
                        usdt_cny = trade_usdt*u2c
                        str = "Total  USDT: %.4f USDT (%.2f CNY)" % (trade_usdt, usdt_cny)
                        print(str)
                        ftext += str+'\n'
                        str = "Invest Cost: %.4f USDT (%.2f CNY)" % (usdt, usdt*u2c)
                        print(str)
                        ftext += str+'\n'
                        str = "Buy  Amount: %.6f BTC (%.2f CNY)" % (amount, amount*price_now*u2c)
                        print(str)
                        ftext += str+'\n'
                        ftext = print_next_exe_time(every_sec, ftext)
                        str = "Zero Time: %s (%.2f H | %.2f D)" % (
                            empty_usdt_time, remain_hours, remain_hours/24)
                        print(str)
                        ftext += str+'\n'
                        ftext = place_order_process(
                            test_price, price_now, amount, 'buy-limit', ftext, time_line, u2c)
                        ORDER_ID = ''
                        fobj.write(ftext)
                        return every_sec
                    else:
                        str = "Run out of USDT or Price < %.2f, wait to continue..." % bottom
                        print(str)
                        ftext += str+'\n'
                        ftext = print_next_exe_time(every_sec, ftext)
                        fobj.write(ftext)
                        return every_sec
                else:
                    str = "Price > %.2f, Check if it can be sold..." % target_price
                    print(str)
                    ftext += str+'\n'
                    profit_now = profit_cny_now(price_now, u2c)
                    if profit_now > profit_cny:
                        ftext = batch_sell_process(test_price, price_now,
                                                   ftext, time_line, u2c, profit_cny, max_sell_count)
                        ftext = print_next_exe_time(every_sec, ftext)
                        fobj.write(ftext)
                        return every_sec
                    else:
                        str = "Profit Now: %.2f <= %.2f So don't sell" % (
                            profit_now, profit_cny)
                        print(str)
                        ftext += str+'\n'
                        ftext = print_next_exe_time(every_sec, ftext)
                        fobj.write(ftext)
                        return every_sec
            else:
                str = "Can't get price, wait %i seconds for next operate" % every_sec
                print(str)
                ftext += str+'\n'
                fobj.write(ftext)
                return every_sec
        else:
            str = "Already reach target amount, Invest PAUSE!"
            print(str)
            ftext += str+'\n'
            fobj.write(ftext)
            return every_sec


if __name__ == '__main__':
    while True:
        try:
            with open(PARAMS, 'r') as fread:
                params_str = fread.read().strip()
                every_sec, below_price, bottom_price, ori_usdt, factor, target_amount, min_usdt, max_rate, deal_date, deal_time, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate = params_str.split(
                    ' ')
                every_sec = int(every_sec)
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
                max_sell_count = int(max_sell_count)
                min_sec_rate = float(min_sec_rate)
                max_sec_rate = float(max_sec_rate)
                code = exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt,
                                       factor, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate)
                if code == 0:
                    break
                else:
                    for remaining in range(int(code), 0, -1):
                        sys.stdout.write("\r")
                        sys.stdout.write(
                            "Please wait {:2d} seconds for next operate".format(remaining))
                        sys.stdout.flush()
                        time.sleep(1)
                        if remaining % 10 == 0:
                            with open(PARAMS, 'r') as f:
                                line_str = f.read().strip()
                                if line_str[0:4] != params_str[0:4]:
                                    break
                    sys.stdout.write("\r                                                      \n")
        except:
            print("Some Unexpected Error, Please Break Program to check!!")
            time.sleep(300)
