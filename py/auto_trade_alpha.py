# -*- coding: utf-8 -*-
import imp
from Utils import *
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
WAIT_SEND_SEC = 18


def fees_rate():
    return 1-0.002


def buy_price_rate():
    return 1.00015


def sell_price_rate():
    return 0.99995


def get_price_now():
    try:
        return float(get_kline('btcusdt', '1min', 1)['data'][0]['close'])
    except:
        return 0


def usd2cny():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'CNY'")
    return round(data[0][0], 4)


def usdt2usd():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'USDT'")
    return round(1/data[0][0], 4)

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
        return 'Some unknow error happened when Place New Order!'


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

def get_all_btc_amount():
    rows = select_db("SELECT sum(amount) FROM properties WHERE currency_id = 6")
    return rows[0][0]


def btc_ave_cost():
    global acc_id
    rows = select_db("SELECT price, amount, fees FROM deal_records WHERE account = '%s' and auto_sell = 0" % acc_id)
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
    global buy_price_period
    global sell_price_period
    global buy_period_move
    global WAIT_SEND_SEC
    if test_price == 0:
        str = place_new_order("%.2f" % price, "%.6f" % amount, deal_type)
        print(str)
        ftext += str+'\n'
        time.sleep(WAIT_SEND_SEC)
        if deal_type.find('buy-limit') > -1:
            str = "%i Deal Records added" % update_huobi_deal_records(time_line)
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
            btc_level_now = btc_hold_level(price)
            profit_now = profit_cny_now(price, u2c)
            str = "BTC Now: %.8f (%.1f CNY) Total: %.1f CNY Level: %.2f%%" % (
                trade_btc, btc_cny, usdt_cny+btc_cny, btc_level_now)
            print(str)
            ftext += str+'\n'
            # str = "BTC Level Now: %.2f%%  Ave: %.2f Profit Now: %.2f CNY" % (
            #     btc_level_now, btc_ave_cost(), profit_now)
            # print(str)
            # ftext += str+'\n'
            if buy_price_period > 0 and buy_period_move > 0:
                new_buy_price_period = int(btc_level_now/buy_period_move)
                if new_buy_price_period < 2:
                    new_buy_price_period = 2
                update_buy_price_period(new_buy_price_period)
                buy_price_period = new_buy_price_period
                str = "Minimum Price Period Updated to: %i Minutes" % new_buy_price_period
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
        sim_btc_level, sim_ave_price = cal_sim_btc_level(price, amount)
        str = "Sim BTC Level: %.2f%%, Ave: %.2f" % (sim_btc_level, sim_ave_price)
        print(str)
        ftext += str+'\n'
    return ftext

def cal_sim_btc_level(price, amount, type='buy'):
    global ori_usdt
    btc_amount = float(get_total_btc())  #get_all_btc_amount()
    usdt = float(get_trade_usdt())
    other_btc = 5.3 # 非短线交易的比特币数量
    other_usdt_cost = other_btc*6450 # 暂时先写死，以后有时间再研究
    cost_usdt = ori_usdt - usdt + other_usdt_cost
    if type == 'buy':
        sim_usdt = usdt - price*amount
        sim_btc_amount = btc_amount + amount*fees_rate()
        sim_cost_usdt = cost_usdt + price*amount
    if type == 'sell':
        sim_usdt = usdt + price*amount*fees_rate()
        sim_btc_amount = btc_amount - amount
        sim_cost_usdt = cost_usdt - price*amount
    sim_btc_usdt = price*sim_btc_amount
    sim_btc_level = sim_btc_usdt/(sim_btc_usdt+sim_usdt)*100
    sim_ave_price = sim_cost_usdt/(sim_btc_amount+other_btc)
    return [sim_btc_level, sim_ave_price]


def profit_cny_now(price, u2c):
    total_btc_amount = get_total_btc()
    if total_btc_amount > 0.00000001:
        btc_total_value = price*total_btc_amount*fees_rate()
        btc_total_cost = btc_ave_cost()*total_btc_amount
        return round((btc_total_value-btc_total_cost)*u2c, 2)
    else:
        return 0


def clear_deal_records():
    global acc_id
    sql = "DELETE FROM deal_records WHERE account = '%s' and auto_sell = 0" % acc_id
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
            arr[1] = str(new_below_price)
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        if new_below_price > 0:  # 定价的策略和买最低价的策略无法并存
            update_buy_price_period(0)
        return 1
    except:
        return 0


def update_buy_price_period(new_value):
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[17] = str(new_value)
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        if new_value > 0:  # 定价的策略和买最低价的策略无法并存
            update_below_price(0)
        return 1
    except:
        return 0


def setup_force_sell():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[20] = '1'
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
            arr[20] = '0'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def reset_test_price():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[11] = '0'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


def btc_hold_level(price):
    amounts = {'usdt': 0, 'btc': 0}
    for item in get_balance(ACCOUNT_ID)['data']['list']:
        for currency in ['usdt', 'btc']:
            if item['currency'] == currency:
                amounts[currency] += float(item['balance'])
    btc_usdt = price*amounts['btc']
    usdt = amounts['usdt']
    return btc_usdt/(btc_usdt+usdt)*100


def print_next_exe_time(every_sec, ftext):
    next_hours = float(every_sec/3600)
    delta_next_hours = timedelta(hours=next_hours)
    next_exe_time = to_t(datetime.now() + delta_next_hours)
    str = "Next Time: %s (%.2f M | %.2f H)" % (
        next_exe_time, every_sec/60, every_sec/3600)
    print(str)
    ftext += str+'\n'
    return ftext


# 检查是否超出设定的卖出额度，若超出则少卖一些
def check_sell_amount(sell_price, sell_amount, usdt_now, sell_max_usd):
    over_sell = False
    ut2u = usdt2usd()
    if (usdt_now + sell_price*sell_amount*fees_rate())*ut2u > sell_max_usd:
        sell_amount = round((sell_max_usd/ut2u-usdt_now)/sell_price/fees_rate(), 6)
        over_sell = True
    return sell_amount, over_sell


def batch_sell_process(test_price, price, base_price, ftext, time_line, u2c, profit_cny, max_sell_count):
    global ORDER_ID
    global FORCE_SELL
    global sell_max_cny
    global acc_id
    usdt_now = get_trade_usdt()
    sell_max_usd = sell_max_cny/u2c
    if max_sell_count > 0 and usdt_now < sell_max_usd:
        rows = select_db(
            "SELECT id, amount-fees as amount, created_at, price FROM deal_records WHERE account = '%s' and auto_sell = 0 ORDER BY created_at ASC LIMIT %i" % (acc_id, max_sell_count))
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
                        # 检查是否超出设定的卖出额度，若超出则少卖一些
                        sell_amount, over_sell = check_sell_amount(sell_price, sell_amount, usdt_now, sell_max_usd)
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
                            if over_sell:
                                rs = select_db(
                                    "SELECT created_at FROM deal_records WHERE account = '%s' and auto_sell = 0 ORDER BY created_at DESC LIMIT 1" % acc_id)
                                update_time_line(rs[0][0])
                                clear_deal_records()
                                str = "Time Line Updated to: %s And Clear Records!" % created_at
                                print(str)
                                ftext += str+'\n'
                            else:
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
        str = "Stop Sell Because Max Sell Count = 0 or USDT > Max Sell"
        print(str)
        ftext += str+'\n'
    return ftext


def get_min_max_price(buy_price_period, sell_price_period):
    try:
        arr = []
        if buy_price_period == 0:
            buy_price_period = 1
        root = get_huobi_price('btcusdt', '1min', buy_price_period)
        for data in root["data"]:
            arr.append(data["low"])
        min_price = min(arr)
        arr = []
        if sell_price_period == 0:
            sell_price_period = 1
        root = get_huobi_price('btcusdt', '1min', sell_price_period)
        for data in root["data"]:
            arr.append(data["high"])
        max_price = max(arr)
        return [min_price, max_price]
    except:
        return [0, 0]


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
        if idx == 0 and int(price_now) <= int(min(a)):
            return [price_now, min(a), True]
        elif idx == 0 and price_now >= min(a):
            return [price_now, min(a), False]
        elif len(a)+idx == a.index(min(a)):
            return [price_now, min(a), True]
        else:
            return [price_now, min(a), False]
    except:
        return [0, 0, False]


def max_price_in(size):
    try:
        a = []
        if size == 0:
            size = 1
        root = get_huobi_price('btcusdt', '1min', size)
        price_now = float(root['data'][0]['close'])
        for data in root["data"]:
            a.append(data["high"])
        a.reverse()
        if price_now >= max(a):
            return [price_now, max(a), True]
        else:
            return [price_now, max(a), False]
    except:
        return [0, 0, False]


def reset_force_trade():
    global ORDER_ID
    global FORCE_BUY
    global FORCE_SELL
    ORDER_ID = ''
    FORCE_BUY = False
    FORCE_SELL = False


def last_buy_interval():
    global acc_id
    try:
        rows = select_db(
            "SELECT created_at FROM deal_records WHERE account = '%s' and auto_sell = 0 ORDER BY created_at DESC LIMIT 1" % acc_id)
        start_time = datetime.strptime(rows[0][0], "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(get_now(), "%Y-%m-%d %H:%M:%S")
        total_seconds = (end_time - start_time).total_seconds()
        return int(total_seconds)
    except:
        return last_sell_interval()


def last_sell_interval():
    global acc_id
    try:
        rows = select_db(
            "SELECT updated_at FROM deal_records WHERE account = '%s' and auto_sell = 1 ORDER BY updated_at DESC LIMIT 1" % acc_id)
        start_time = datetime.strptime(rows[0][0], "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(get_now(), "%Y-%m-%d %H:%M:%S")
        total_seconds = (end_time - start_time).total_seconds()
        return int(total_seconds)
    except:
        return 100000


def exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt, factor, max_buy_level, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate):
    global ORDER_ID
    global FORCE_BUY
    global FORCE_SELL
    global LOG_FILE
    global LINE_MARKS
    global min_price
    global max_price
    global buy_price_period
    global every_sec_for_sell
    global acc_id
    with open(LOG_FILE, 'a') as fobj:
        sline = LINE_MARKS
        ftext = sline+'\n'
        now = datetime.now()
        if below_price > 0:
            str = "%s Invest Between: %.2f ~ %.2f %s %s" % (get_now(), bottom_price, below_price, acc_id, ACCOUNT_ID)
        else:
            str = "%s Invest Between: %.2f ~ AUTO" % (get_now(), bottom_price)
        print(str)
        ftext += str+'\n'
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
            price_now = get_price_now()
            if price_now > 0:
                if test_price > 0:
                    str = "Test Price: %.2f Now: %.2f %i_Min: %.2f %i_Max: %.2f" % (test_price, price_now, buy_price_period, min_price, sell_price_period, max_price)
                    price_now = test_price
                    str += '\n' + ("Price Now Update to: %.2f" % price_now)
                else:
                    str = "Price Now: %.2f %i_Min: %.2f %i_Max: %.2f" % (price_now, buy_price_period, min_price, sell_price_period, max_price)
                print(str)
                ftext += str+'\n'
                u2c = usd2cny()
                if test_price > 0 or ((FORCE_BUY == True or price_now <= below_price) and last_buy_interval() > every_sec):
                    ori_usdt = float(ori_usdt)
                    trade_usdt = float(get_trade_usdt())
                    bottom = float(bottom_price)
                    max_usdt = ori_usdt*max_rate
                    btc_level_now = btc_hold_level(price_now)
                    if test_price > 0 or (max_buy_level > 0 and trade_usdt > min_usdt and price_now - bottom >= 0 and btc_level_now < max_buy_level):
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
                        str = "BTC Level: %.2f%% (FORCE_BUY:%s) for AccId: %s(%s)" % (
                            btc_level_now, FORCE_BUY, acc_id, ACCOUNT_ID)
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
                    if FORCE_SELL == True and last_sell_interval() > every_sec_for_sell:
                        ftext = batch_sell_process(0, price_now, below_price,
                                                   ftext, time_line, u2c, -100000, max_sell_count)
                        ftext = print_next_exe_time(every_sec, ftext)
                        fobj.write(ftext)
                        reset_force_sell()
                        return every_sec
                    else:
                        str = "Buy conditions not met, Check if can sell..."
                        print(str)
                        ftext += str+'\n'
                        profit_now = profit_cny_now(price_now, u2c)
                        if max_sell_count > 0 and profit_now > profit_cny and last_sell_interval() > every_sec_for_sell:
                            ftext = batch_sell_process(test_price, price_now, below_price,
                                                       ftext, time_line, u2c, profit_cny, max_sell_count)
                            ftext = print_next_exe_time(every_sec, ftext)
                            fobj.write(ftext)
                            return every_sec
                        else:
                            str = "Profit: %.2f < %.2f or Sell Count = 0 or Sell Time < %i" % (
                                profit_now, profit_cny, every_sec_for_sell)
                            print(str)
                            ftext += str+'\n'
                            ftext = print_next_exe_time(every_sec_for_sell, ftext)
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
                every_sec, below_price, bottom_price, ori_usdt, factor, max_buy_level, target_amount, min_usdt, max_rate, deal_date, deal_time, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate, detect_sec, buy_price_period, sell_price_period, buy_period_move, force_to_sell, min_price_index, every_sec_for_sell, sell_max_cny, acc_id = params_str.split(
                    ' ')
                every_sec = int(every_sec)
                below_price = float(below_price)
                bottom_price = float(bottom_price)
                ori_usdt = float(ori_usdt)
                factor = float(factor)
                max_buy_level = float(max_buy_level)
                target_amount = float(target_amount)
                min_usdt = float(min_usdt)
                max_rate = float(max_rate)/100
                time_line = deal_date+' '+deal_time
                test_price = float(test_price)
                profit_cny = float(profit_cny)
                max_sell_count = int(max_sell_count)
                min_sec_rate = float(min_sec_rate)
                max_sec_rate = float(max_sec_rate)
                detect_sec = int(detect_sec)
                buy_price_period = int(buy_price_period)
                sell_price_period = int(sell_price_period)
                buy_period_move = float(buy_period_move)
                force_to_sell = int(force_to_sell)
                min_price_index = int(min_price_index)
                every_sec_for_sell = int(every_sec_for_sell)
                sell_max_cny = int(sell_max_cny)
                min_price, max_price = get_min_max_price(buy_price_period, sell_price_period)
                if force_to_sell > 0:
                    FORCE_SELL = True
                code = exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt,
                                       factor, max_buy_level, target_amount, min_usdt, max_rate, time_line, test_price, profit_cny, max_sell_count, min_sec_rate, max_sec_rate)
                reset_test_price()
                global ACCOUNT_ID
                if acc_id == '170':
                    ACCOUNT_ID = 6582761    
                    # ACCESS_KEY = "0b259f2c-h6n2d4f5gh-4c7eb89b-845c8"
                    # SECRET_KEY = "086b3b20-4fc8db0d-21b8ad20-9bf64"
                    # PHONE = '17099311026'
                if acc_id == '135':
                    ACCOUNT_ID = 6565695    
                    # ACCESS_KEY = "c9c13a21-58449e8a-af5fdfd2-mn8ikls4qg"
                    # SECRET_KEY = "7aa1c5a1-0c7d2bdf-5dd73a82-34136"
                    # PHONE = '13581706025'
                if code == 0:
                    break
                else:
                    for remaining in range(int(code), 0, -1):
                        sys.stdout.write("\r")
                        sys.stdout.write(
                            "Please wait {:2d} seconds for next operate".format(remaining))
                        if buy_price_period == 0:
                            sys.stdout.flush()
                        time.sleep(1)
                        if remaining % detect_sec == 0:
                            reset_force_trade()
                            with open(PARAMS, 'r') as f:
                                line_str = f.read().strip()
                                if line_str[0:5] != params_str[0:5]:
                                    break
                            if below_price > 0:
                                price_now = get_price_now()
                                over_time = last_buy_interval() > every_sec
                                sys.stdout.write("\r")
                                sys.stdout.write("now: %.2f below_price: %.2f over_time: %s                " % (price_now, below_price, over_time))
                                sys.stdout.write("\n")
                                if price_now > 0 and price_now < below_price and over_time:
                                    FORCE_BUY = True
                                    break
                            if buy_price_period > 0:
                                price_now, min_price, min_price_in_wish = min_price_in(min_price_index, buy_price_period)
                                over_time = last_buy_interval() > every_sec
                                if price_now > 0 and min_price > 0:
                                    sys.stdout.write("\r")
                                    sys.stdout.write("now: %.2f %im_min: %.2f over_time: %s                 " % (price_now, buy_price_period, min_price, over_time))
                                    sys.stdout.write("\n")
                                    if min_price_in_wish and over_time:
                                        FORCE_BUY = True
                                        break
                            if sell_price_period > 0:
                                price_now, max_price, max_price_in_wish = max_price_in(sell_price_period)
                                over_time = last_sell_interval() > every_sec_for_sell
                                if price_now > 0 and max_price > 0:
                                    sys.stdout.write("\r")
                                    sys.stdout.write("now: %.2f %im_max: %.2f over_time: %s                 " % (price_now, sell_price_period, max_price, over_time))
                                    sys.stdout.write("\n")
                                    if max_price_in_wish and over_time:
                                        setup_force_sell()
                                        break
                    sys.stdout.write("\r                                                      \n")
        except:
            print("Some Unexpected Error, Please Break Program to check!!")
            time.sleep(300)
