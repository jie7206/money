# -*- coding: utf-8 -*-
from HuobiServices import *
from update_all import *
from update_assets import *
from deal_records import *
from open_orders import *
from huobi_price import *

ORDER_ID = ''
FORCE_BUY = False
FORCE_SELL = False
LOG_FILE = 'auto_invest_log.txt'
LINE_MARKS = "-"*70


def fees_rate():
    return 1-0.002


def buy_price_rate():
    return 1.0005


def sell_price_rate():
    return 0.9997


def get_price_now():
    try:
        return float(get_kline('btcusdt', '1min', 1)['data'][0]['close'])
    except:
        return 0


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
        return 0


def get_total_btc():
    try:
        amount = 0
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'btc':
                amount += float(item['balance'])
        return amount
    except:
        return 0


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


def place_order_process(test_price, price, amount, deal_type, ftext, time_line, u2c):
    global below_price
    global min_price_period
    global min_price_period_tune
    if test_price == 0:
        str = place_new_order("%.2f" % price, "%.6f" % amount, deal_type)
        print(str)
        ftext += str+'\n'
        time.sleep(3)
        if deal_type.find('buy-limit') > -1:
            str = "%i Deal Records added" % update_huobi_deal_records(time_line)
            print(str)
            ftext += str+'\n'
            if min_price_period > 0:
                min_price, max_price = get_min_max_price(min_price_period)
                if min_price > 0 and min_price != below_price:
                    update_below_price("%.2f" % min_price)
                    str = "Below Price Updated to: %.2f" % min_price
                    print(str)
                    ftext += str+'\n'
        trade_usdt = float(get_trade_usdt())
        if trade_usdt > 0:
            usdt_cny = trade_usdt*u2c
            str = "USDT Trade Now: %.4f (%.2f CNY)" % (
                trade_usdt, usdt_cny)
            print(str)
            ftext += str+'\n'
            trade_btc = float(get_trade_btc())
            btc_cny = trade_btc*price*u2c
            str = "BTC Trade Now: %.8f (%.2f CNY) Total: %.2f CNY" % (
                trade_btc, btc_cny, usdt_cny+btc_cny)
            print(str)
            ftext += str+'\n'
            btc_level_now = btc_hold_level(price, u2c)
            profit_now = profit_cny_now(price, u2c)
            str = "BTC Level Now: %.2f%%  Ave: %.2f Profit Now: %.2f CNY" % (
                btc_level_now, btc_ave_cost(), profit_now)
            print(str)
            ftext += str+'\n'
            if min_price_period > 0 and min_price_period_tune > 0:
                new_min_price_period = int(btc_level_now/min_price_period_tune)
                if new_min_price_period < 2:
                    new_min_price_period = 2
                update_min_price_period(new_min_price_period)
                min_price_period = new_min_price_period
                str = "Minimum Price Period Updated to: %i Minutes" % new_min_price_period
                print(str)
                ftext += str+'\n'
            str = "%i Huobi Assets Updated, Send Order Process Completed" % update_all_huobi_assets()
            print(str)
            ftext += str+'\n'
            if trade_btc > target_amount:
                str = "Already reach target amount, Invest PAUSE!"
                print(str)
                ftext += str+'\n'
    else:
        str = "Sim Order Price: %.2f, Amount: %.6f, Type: %s" % (price, amount, deal_type)
        print(str)
        ftext += str+'\n'
    return ftext


def profit_cny_now(price, u2c):
    total_btc_amount = get_total_btc()
    if total_btc_amount > 0.00000001:
        btc_total_value = price*total_btc_amount*fees_rate()
        btc_total_cost = btc_ave_cost()*total_btc_amount
        return round((btc_total_value-btc_total_cost)*u2c, 2)
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
            arr[9] = date_str
            arr[10] = time_str
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def update_below_price(new_below_price):
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[1] = new_below_price
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def update_min_price_period(new_value):
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[17] = str(new_value)
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def setup_force_sell():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[19] = '1'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def reset_force_sell():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[19] = '0'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def btc_hold_level(price, u2c):
    amounts = {'usdt': 0, 'btc': 0}
    for item in get_balance(ACCOUNT_ID)['data']['list']:
        for currency in ['usdt', 'btc']:
            if item['currency'] == currency:
                amounts[currency] += float(item['balance'])
    btc_cny = price*amounts['btc']*u2c
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


def batch_sell_process(test_price, price, base_price, ftext, time_line, u2c, profit_cny, max_sell_count):
    if max_sell_count > 0:
        global ORDER_ID
        global FORCE_SELL
        rows = select_db(
            "SELECT id, amount-fees as amount, created_at, price FROM deal_records WHERE auto_sell = 0 ORDER BY created_at ASC LIMIT %i" % max_sell_count)
        if len(rows) > 0:
            ids = []
            sell_amount = 0
            sell_count = 0
            sell_profit_total = 0
            sum_for_ave = 0
            cost_price_ave = 0
            created_at = ''
            sell_price = round(price*sell_price_rate(), 2)
            profit_cny = (1+(price-base_price)**2/10000)*profit_cny
            for row in rows:
                id = row[0]
                amount = row[1]
                created_at = row[2]
                cost_price = row[3]
                ids.append(id)
                sell_count += 1
                sell_profit_total += (sell_price-cost_price)*amount*fees_rate()*u2c
                sell_amount += amount
                sum_for_ave += cost_price*amount
                cost_price_ave = round(sum_for_ave/sell_amount, 2)
                if FORCE_SELL == True and sell_count != max_sell_count:
                    continue
                else:
                    if sell_profit_total > profit_cny or sell_count == max_sell_count:
                        # 提交订单
                        ftext = place_order_process(test_price, sell_price,
                                                    sell_amount, 'sell-limit', ftext, time_line, u2c)
                        # 如果提交成功，将这些交易记录标示为已自动卖出并更新下单编号及已实现损益
                        if test_price == 0 and len(ORDER_ID) > 0:
                            real_profit = round(sell_profit_total, 4)
                            sql = "UPDATE deal_records SET auto_sell = 1, order_id = '%s', price = %.2f, amount = %.6f, real_profit = %.2f, updated_at = '%s' WHERE id = %i" % (
                                ORDER_ID, cost_price_ave, sell_amount, real_profit, get_now(), ids[-1])
                            CONN.execute(sql)
                            CONN.commit()
                            for id in ids[0:-1]:
                                sql = "DELETE FROM deal_records WHERE id = %i" % id
                                CONN.execute(sql)
                                CONN.commit()
                            ORDER_ID = ''
                            str = "%i Deal Records Auto Sold and Combined, Sold Profit: %.2f CNY" % (
                                len(ids), sell_profit_total)
                            print(str)
                            ftext += str+'\n'
                            # 更新记录time_line文档
                            update_time_line(created_at)
                            str = "Time Line Updated to: %s" % created_at
                            print(str)
                            ftext += str+'\n'
                        else:
                            str = "Sim Update %i Deal Records with Profit: %.2f CNY" % (
                                len(ids), sell_profit_total)
                            print(str)
                            ftext += str+'\n'
                        break
    else:
        str = "Stop Sell Process Because Max Sell Count = 0"
        print(str)
        ftext += str+'\n'
    return ftext


def get_min_max_price(size):
    try:
        arr = []
        if size == 0:
            size = 1
        root = get_huobi_price('btcusdt', '1min', size)
        for data in root["data"]:
            arr.append(data["low"])
        return [min(arr), max(arr)]
    except:
        return 0


def min_price_in(idx, size):
    try:
        a = []
        if size == 0:
            size = 1
        root = get_huobi_price('btcusdt', '1min', size)
        price_now = float(root['data'][0]['close'])
        for data in root["data"]:
            a.append(data["low"])
        a.reverse()
        if price_now >= max(a):
            return [price_now, min(a), max(a), a, False, True]
        elif idx == 0 and price_now <= min(a):
            return [price_now, min(a), max(a), a, True, False]
        elif idx == 0 and price_now >= min(a):
            return [price_now, min(a), max(a), a, False, False]
        elif len(a)+idx == a.index(min(a)):
            return [price_now, min(a), max(a), a, True, False]
        else:
            return [price_now, min(a), max(a), a, False, False]
    except:
        return [0, 0, 0, [], False, False]


def reset_force_trade():
    global ORDER_ID
    global FORCE_BUY
    global FORCE_SELL
    ORDER_ID = ''
    FORCE_BUY = False
    FORCE_SELL = False


def last_order_interval():
    try:
        rows = select_db(
            "SELECT created_at FROM deal_records WHERE auto_sell = 0 ORDER BY created_at DESC LIMIT 1")
        start_time = datetime.strptime(rows[0][0], "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(get_now(), "%Y-%m-%d %H:%M:%S")
        total_seconds = (end_time - start_time).total_seconds()
        return int(total_seconds)
    except:
        return 0


def last_sell_interval():
    try:
        rows = select_db(
            "SELECT updated_at FROM deal_records WHERE auto_sell = 1 ORDER BY updated_at DESC LIMIT 1")
        start_time = datetime.strptime(rows[0][0], "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(get_now(), "%Y-%m-%d %H:%M:%S")
        total_seconds = (end_time - start_time).total_seconds()
        return int(total_seconds)
    except:
        return 0


def exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt, factor, max_buy_level, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate):
    global ORDER_ID
    global FORCE_BUY
    global FORCE_SELL
    global LOG_FILE
    global LINE_MARKS
    global min_price
    global max_price
    global min_price_period
    with open(LOG_FILE, 'a') as fobj:
        sline = LINE_MARKS
        ftext = sline+'\n'
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
                str = "Price %s: %.2f Min: %.2f Max: %.2f Within: %i Minutes" % (
                    mode, price_now, min_price, max_price, min_price_period)
                print(str)
                ftext += str+'\n'
                u2c = usd_to_cny()
                if (FORCE_BUY == True or min_price_period == 0) and last_order_interval() > every_sec:
                    ori_usdt = float(ori_usdt)
                    trade_usdt = float(get_trade_usdt())
                    bottom = float(bottom_price)
                    max_usdt = ori_usdt*max_rate
                    btc_level_now = btc_hold_level(price_now, u2c)
                    if max_buy_level > 0 and trade_usdt > min_usdt and price_now - bottom >= 0 and btc_level_now < max_buy_level:
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
                        str = "BTC Level: %.2f%% (FORCE_BUY:%s)" % (
                            btc_level_now, FORCE_BUY)
                        print(str)
                        ftext += str+'\n'
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
                            test_price, round(price_now*buy_price_rate(), 2), amount, 'buy-limit', ftext, time_line, u2c)
                        fobj.write(ftext)
                        return every_sec
                    else:
                        str = "STOP Buy Process! Because Max Buy Level = 0\n"
                        str += "or Over %.2f%% or Price < %.2f or Buy Time < %i" % (
                            max_buy_level, bottom, every_sec)
                        print(str)
                        ftext += str+'\n'
                        ftext = print_next_exe_time(every_sec, ftext)
                        fobj.write(ftext)
                        reset_force_sell()
                        return every_sec
                else:
                    if FORCE_SELL == True:
                        ftext = batch_sell_process(0, price_now, below_price,
                                                   ftext, time_line, u2c, -100000, max_sell_count)
                        ftext = print_next_exe_time(every_sec, ftext)
                        fobj.write(ftext)
                        reset_force_sell()
                        return every_sec
                    else:
                        str = "Buy Time < %i or Price > %.2f, Check if sell..." % (
                            every_sec, target_price)
                        print(str)
                        ftext += str+'\n'
                        profit_now = profit_cny_now(price_now, u2c)
                        if max_sell_count > 0 and profit_now > profit_cny and last_sell_interval() > every_sec:
                            ftext = batch_sell_process(test_price, price_now, below_price,
                                                       ftext, time_line, u2c, profit_cny, max_sell_count)
                            ftext = print_next_exe_time(every_sec, ftext)
                            fobj.write(ftext)
                            return every_sec
                        else:
                            str = "Profit: %.2f < %.2f or Sell Count = 0 or Sell Time < %i" % (
                                profit_now, profit_cny, every_sec)
                            print(str)
                            ftext += str+'\n'
                            ftext = print_next_exe_time(every_sec, ftext)
                            fobj.write(ftext)
                            return every_sec
            else:
                str = "Can't get price, wait 5 seconds for next operate"
                print(str)
                ftext += str+'\n'
                fobj.write(ftext)
                return 5
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
                every_sec, below_price, bottom_price, ori_usdt, factor, max_buy_level, target_amount, min_usdt, max_rate, deal_date, deal_time, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate, detect_sec, min_price_period, min_price_period_tune, force_to_sell, min_price_index = params_str.split(
                    ' ')
                every_sec = int(every_sec)
                below_price = float(below_price)
                bottom_price = float(bottom_price)
                ori_usdt = float(ori_usdt)
                factor = float(factor)
                max_buy_level = float(max_buy_level)
                target_amount = float(target_amount)
                min_usdt = float(min_usdt)
                max_rate = float(max_rate)
                time_line = deal_date+' '+deal_time
                test_price = float(test_price)
                profit_cny = float(profit_cny)
                max_sell_count = int(max_sell_count)
                min_sec_rate = float(min_sec_rate)
                max_sec_rate = float(max_sec_rate)
                detect_sec = int(detect_sec)
                min_price_period = int(min_price_period)
                min_price_period_tune = float(min_price_period_tune)
                force_to_sell = int(force_to_sell)
                min_price_index = int(min_price_index)
                min_price, max_price = get_min_max_price(min_price_period)
                if force_to_sell > 0:
                    FORCE_SELL = True
                code = exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt,
                                       factor, max_buy_level, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate)
                if code == 0:
                    break
                else:
                    for remaining in range(int(code), 0, -1):
                        sys.stdout.write("\r")
                        sys.stdout.write(
                            "Please wait {:2d} seconds for next operate".format(remaining))
                        if min_price_period == 0:
                            sys.stdout.flush()
                        time.sleep(1)
                        if remaining % detect_sec == 0:
                            reset_force_trade()
                            with open(PARAMS, 'r') as f:
                                line_str = f.read().strip()
                                if line_str[0:4] != params_str[0:4]:
                                    break
                            if min_price_period > 0:
                                price_now, min_price, max_price, arr, min_price_in_wish, price_ge_max = min_price_in(
                                    min_price_index, min_price_period)
                                if price_now > 0 and min_price > 0:
                                    sys.stdout.write("\r")
                                    sys.stdout.write("now: %.2f %im_min: %.2f max: %.2f %s" %
                                                     (price_now, min_price_period, min_price, max_price, arr[min_price_index-4:-1]))
                                    sys.stdout.write("\n")
                                    if price_ge_max and last_sell_interval() > every_sec:
                                        setup_force_sell()
                                        break
                                    if min_price_in_wish and last_order_interval() > every_sec:
                                        FORCE_BUY = True
                                        break
                    sys.stdout.write("\r                                                      \n")
        except:
            print("Some Unexpected Error, Please Break Program to check!!")
            time.sleep(300)
