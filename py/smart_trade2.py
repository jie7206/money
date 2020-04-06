# -*- coding: utf-8 -*-

# 导入所有的包
import sys
import json
import time
import sqlite3
import base64
import hashlib
import hmac
import json
import urllib
import urllib.parse
import urllib.request
import requests
from db import *
from update_all import *
from update_assets import *
from deal_records import *
from open_orders import *
from huobi_price import *


# 建立数据库实例、设定文档路径、Log文档路径
CONN = sqlite3.connect(db_path())
PARAMS = get_params_path()
LOG_FILE = 'auto_invest_log.txt'

# 初始化火币账号ID及API密钥
ACCOUNT_ID = 0
ACCESS_KEY = ""
SECRET_KEY = ""
PHONE = ""

# 初始化自动下单参数
ORDER_ID = ''
FORCE_BUY = False
FORCE_SELL = False
WAIT_SEND_SEC = 30
MIN_SELL_USDT = 5.2
ALREADY_SEND_BUY = False
LINE_MARKS = "-"*70

# 火币API请求地址
MARKET_URL = "https://api.huobi.pro"
TRADE_URL = "https://api.huobi.pro"


########## 火币API开始 ####################################################################


# 火币API函数：'Timestamp': '2017-06-02T06:13:49'
def http_get_request(url, params, add_to_headers=None):
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
    }
    if add_to_headers:
        headers.update(add_to_headers)
    postdata = urllib.parse.urlencode(params)
    response = requests.get(url, postdata, headers=headers, timeout=10)
    try:

        if response.status_code == 200:
            return response.json()
        else:
            return
    except BaseException as e:
        print("httpGet failed, detail is:%s,%s" %(response.text,e))
        return


# 火币API函数
def http_post_request(url, params, add_to_headers=None):
    headers = {
        "Accept": "application/json",
        'Content-Type': 'application/json'
    }
    if add_to_headers:
        headers.update(add_to_headers)
    postdata = json.dumps(params)
    response = requests.post(url, postdata, headers=headers, timeout=10)
    try:

        if response.status_code == 200:
            return response.json()
        else:
            return
    except BaseException as e:
        print("httpPost failed, detail is:%s,%s" %(response.text,e))
        return


# 火币API函数
def api_key_get(params, request_path):
    method = 'GET'
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S')
    params.update({'AccessKeyId': ACCESS_KEY,
                   'SignatureMethod': 'HmacSHA256',
                   'SignatureVersion': '2',
                   'Timestamp': timestamp})

    host_url = TRADE_URL
    host_name = urllib.parse.urlparse(host_url).hostname
    host_name = host_name.lower()
    params['Signature'] = create_sign(params, method, host_name, request_path, SECRET_KEY)

    url = host_url + request_path
    return http_get_request(url, params)


# 火币API函数
def api_key_post(params, request_path):
    method = 'POST'
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S')
    params_to_sign = {'AccessKeyId': ACCESS_KEY,
                      'SignatureMethod': 'HmacSHA256',
                      'SignatureVersion': '2',
                      'Timestamp': timestamp}

    host_url = TRADE_URL
    host_name = urllib.parse.urlparse(host_url).hostname
    host_name = host_name.lower()
    params_to_sign['Signature'] = create_sign(params_to_sign, method, host_name, request_path, SECRET_KEY)
    url = host_url + request_path + '?' + urllib.parse.urlencode(params_to_sign)
    return http_post_request(url, params)


# 火币API函数
def create_sign(pParams, method, host_url, request_path, secret_key):
    sorted_params = sorted(pParams.items(), key=lambda d: d[0], reverse=False)
    encode_params = urllib.parse.urlencode(sorted_params)
    payload = [method, host_url, request_path, encode_params]
    payload = '\n'.join(payload)
    payload = payload.encode(encoding='UTF8')
    secret_key = secret_key.encode(encoding='UTF8')

    digest = hmac.new(secret_key, payload, digestmod=hashlib.sha256).digest()
    signature = base64.b64encode(digest)
    signature = signature.decode()
    return signature


# 火币API函数：获取KLine
def get_kline(symbol, period, size=150):
    """
    :param symbol
    :param period: 可选值：{1min, 5min, 15min, 30min, 60min, 1day, 1mon, 1week, 1year }
    :param size: 可选值： [1,2000]
    :return:
    """
    params = {'symbol': symbol,
              'period': period,
              'size': size}

    url = MARKET_URL + '/market/history/kline'
    return http_get_request(url, params)


# 火币API函数：获取market depth
def get_depth(symbol, type):
    """
    :param symbol
    :param type: 可选值：{ percent10, step0, step1, step2, step3, step4, step5 }
    :return:
    """
    params = {'symbol': symbol,
              'type': type}

    url = MARKET_URL + '/market/depth'
    return http_get_request(url, params)


# 火币API函数：获取trade detail
def get_trade(symbol):
    """
    :param symbol
    :return:
    """
    params = {'symbol': symbol}

    url = MARKET_URL + '/market/trade'
    return http_get_request(url, params)


# 火币API函数：Tickers detail
def get_tickers():
    """
    :return:
    """
    params = {}
    url = MARKET_URL + '/market/tickers'
    return http_get_request(url, params)


# 火币API函数：获取merge ticker
def get_ticker(symbol):
    """
    :param symbol:
    :return:
    """
    params = {'symbol': symbol}

    url = MARKET_URL + '/market/detail/merged'
    return http_get_request(url, params)


# 火币API函数：获取 Market Detail 24小时成交量数据
def get_detail(symbol):
    """
    :param symbol
    :return:
    """
    params = {'symbol': symbol}

    url = MARKET_URL + '/market/detail'
    return http_get_request(url, params)


# 火币API函数：获取支持的交易对
def get_symbols(long_polling=None):
    """

    """
    params = {}
    if long_polling:
        params['long-polling'] = long_polling
    path = '/v1/common/symbols'
    return api_key_get(params, path)


# 火币API函数：Get available currencies
def get_currencies():
    """
    :return:
    """
    params = {}
    url = MARKET_URL + '/v1/common/currencys'

    return http_get_request(url, params)


# 火币API函数：Get all the trading assets
def get_trading_assets():
    """
    :return:
    """
    params = {}
    url = MARKET_URL + '/v1/common/symbols'

    return http_get_request(url, params)


# 火币API函数：获取账号
def get_accounts():
    """
    :return:
    """
    path = "/v1/account/accounts"
    params = {}
    return api_key_get(params, path)


# 火币API函数：获取当前账户资产
def get_balance(acct_id=None):
    """
    :param acct_id
    :return:
    """

    if not acct_id:
        accounts = get_accounts()
        acct_id = accounts['data'][0]['id']

    url = "/v1/account/accounts/{0}/balance".format(acct_id)
    params = {"account-id": acct_id}
    return api_key_get(params, url)


# 火币API函数：创建并执行订单
def send_order(amount, source, symbol, _type, price=0):
    """
    :param amount:
    :param source: 如果使用借贷资产交易，请在下单接口,请求参数source中填写'margin-api'
    :param symbol:
    :param _type: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param price:
    :return:
    """
    try:
        accounts = get_accounts()
        acct_id = accounts['data'][0]['id']
    except BaseException as e:
        print('get acct_id error.%s' % e)
        acct_id = ACCOUNT_ID

    params = {"account-id": acct_id,
              "amount": amount,
              "symbol": symbol,
              "type": _type,
              "source": source}
    if price:
        params["price"] = price

    url = '/v1/order/orders/place'
    return api_key_post(params, url)


# 火币API函数：撤销订单
def cancel_order(order_id):
    """

    :param order_id:
    :return:
    """
    params = {}
    url = "/v1/order/orders/{0}/submitcancel".format(order_id)
    return api_key_post(params, url)


# 火币API函数：查询某个订单
def order_info(order_id):
    """

    :param order_id:
    :return:
    """
    params = {}
    url = "/v1/order/orders/{0}".format(order_id)
    return api_key_get(params, url)


# 火币API函数：查询某个订单的成交明细
def order_matchresults(order_id):
    """
    :param order_id:
    :return:
    """
    params = {}
    url = "/v1/order/orders/{0}/matchresults".format(order_id)
    return api_key_get(params, url)


# 火币API函数：查询当前委托、历史委托
def orders_list(symbol, states, types=None, start_date=None, end_date=None, _from=None, direct=None, size=None):
    """
    :param symbol:
    :param states: 可选值 {pre-submitted 准备提交, submitted 已提交, partial-filled 部分成交, partial-canceled 部分成交撤销, filled 完全成交, canceled 已撤销}
    :param types: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param start_date:
    :param end_date:
    :param _from:
    :param direct: 可选值{prev 向前，next 向后}
    :param size:
    :return:
    """
    params = {'symbol': symbol,
              'states': states}
    if types:
        params['types'] = types
    if start_date:
        params['start-date'] = start_date
    if end_date:
        params['end-date'] = end_date
    if _from:
        params['from'] = _from
    if direct:
        params['direct'] = direct
    if size:
        params['size'] = size
    url = '/v1/order/orders'
    return api_key_get(params, url)


# 火币API函数：查询当前成交、历史成交
def orders_matchresults(symbol, types=None, start_date=None, end_date=None, _from=None, direct=None, size=None):
    """
    :param symbol:
    :param types: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param start_date:
    :param end_date:
    :param _from:
    :param direct: 可选值{prev 向前，next 向后}
    :param size:
    :return:
    """
    params = {'symbol': symbol}
    if types:
        params['types'] = types
    if start_date:
        params['start-date'] = start_date
    if end_date:
        params['end-date'] = end_date
    if _from:
        params['from'] = _from
    if direct:
        params['direct'] = direct
    if size:
        params['size'] = size
    url = '/v1/order/matchresults'
    return api_key_get(params, url)


# 火币API函数：查询所有当前帐号下未成交订单
def open_orders(account_id, symbol, size=10, side=''):
    """
    :param symbol:
    :return:
    """
    params = {}
    url = "/v1/order/openOrders"
    if symbol:
        params['symbol'] = symbol
    if account_id:
        params['account-id'] = account_id
    if side:
        params['side'] = side
    if size:
        params['size'] = size
    return api_key_get(params, url)


# 火币API函数：批量取消符合条件的订单
def cancel_open_orders(account_id, symbol, side='', size=50):
    """
    :param symbol:
    :return:
    """
    params = {}
    url = "/v1/order/orders/batchCancelOpenOrders"
    if symbol:
        params['symbol'] = symbol
    if account_id:
        params['account-id'] = account_id
    if side:
        params['side'] = side
    if size:
        params['size'] = size
    return api_key_post(params, url)


# 火币API函数：申请提现虚拟币
def withdraw(address, amount, currency, fee=0, addr_tag=""):
    """
    :param address_id:
    :param amount:
    :param currency:btc, ltc, bcc, eth, etc ...(火币Pro支持的币种)
    :param fee:
    :param addr-tag:
    :return: {
              "status": "ok",
              "data": 700
            }
    """
    params = {'address': address,
              'amount': amount,
              "currency": currency,
              "fee": fee,
              "addr-tag": addr_tag}
    url = '/v1/dw/withdraw/api/create'
    return api_key_post(params, url)


# 申请取消提现虚拟币
def cancel_withdraw(address_id):
    """
    :param address_id:
    :return: {
              "status": "ok",
              "data": 700
            }
    """
    params = {}
    url = '/v1/dw/withdraw-virtual/{0}/cancel'.format(address_id)

    return api_key_post(params, url)



# 火币API函数：创建并执行借贷订单
def send_margin_order(amount, source, symbol, _type, price=0):
    """
    :param amount:
    :param source: 'margin-api'
    :param symbol:
    :param _type: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param price:
    :return:
    """
    try:
        accounts = get_accounts()
        acct_id = accounts['data'][0]['id']
    except BaseException as e:
        print('get acct_id error.%s' % e)
        acct_id = ACCOUNT_ID
    params = {"account-id": acct_id,
              "amount": amount,
              "symbol": symbol,
              "type": _type,
              "source": 'margin-api'}
    if price:
        params["price"] = price
    url = '/v1/order/orders/place'
    return api_key_post(params, url)


# 火币API函数：现货账户划入至借贷账户
def exchange_to_margin(symbol, currency, amount):
    """
    :param amount:
    :param currency:
    :param symbol:
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency,
              "amount": amount}
    url = "/v1/dw/transfer-in/margin"
    return api_key_post(params, url)


# 火币API函数：借贷账户划出至现货账户
def margin_to_exchange(symbol, currency, amount):
    """
    :param amount:
    :param currency:
    :param symbol:
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency,
              "amount": amount}
    url = "/v1/dw/transfer-out/margin"
    return api_key_post(params, url)


# 火币API函数：申请借贷
def get_margin(symbol, currency, amount):
    """
    :param amount:
    :param currency:
    :param symbol:
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency,
              "amount": amount}
    url = "/v1/margin/orders"
    return api_key_post(params, url)


# 火币API函数：归还借贷
def repay_margin(order_id, amount):
    """
    :param order_id:
    :param amount:
    :return:
    """
    params = {"order-id": order_id,
              "amount": amount}
    url = "/v1/margin/orders/{0}/repay".format(order_id)
    return api_key_post(params, url)


# 火币API函数：借贷订单
def loan_orders(symbol, currency, start_date="", end_date="", start="", direct="", size=""):
    """
    :param symbol:
    :param currency:
    :param direct: prev 向前，next 向后
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency}
    if start_date:
        params["start-date"] = start_date
    if end_date:
        params["end-date"] = end_date
    if start:
        params["from"] = start
    if direct and direct in ["prev", "next"]:
        params["direct"] = direct
    if size:
        params["size"] = size
    url = "/v1/margin/loan-orders"
    return api_key_get(params, url)


# 火币API函数：借贷账户详情,支持查询单个币种
def margin_balance(symbol):
    """
    :param symbol:
    :return:
    """
    params = {}
    url = "/v1/margin/accounts/balance"
    if symbol:
        params['symbol'] = symbol

    return api_key_get(params, url)


########## 火币API结束 ####################################################################

########## 自定义函数开始 ##################################################################


# 根据设定文档记录赋值火币账号ID及API密钥
def load_api_key():
    global ACCOUNT_ID
    global ACCESS_KEY
    global SECRET_KEY
    global PHONE
    with open(PARAMS, 'r') as f:
        arr = f.read().strip().split(' ')
        acc_id = arr[24]
        if acc_id == '170':
            ACCOUNT_ID = 6582761
            ACCESS_KEY = "0b259f2c-h6n2d4f5gh-4c7eb89b-845c8"
            SECRET_KEY = "086b3b20-4fc8db0d-21b8ad20-9bf64"
            PHONE = '17099311026'
        if acc_id == '135':
            ACCOUNT_ID = 6565695
            ACCESS_KEY = "c9c13a21-58449e8a-af5fdfd2-mn8ikls4qg"
            SECRET_KEY = "7aa1c5a1-0c7d2bdf-5dd73a82-34136"
            PHONE = '13581706025'
    print("********** Updated ACCOUNT_ID: %s PHONE: %s **********" % (ACCOUNT_ID, PHONE))


# 从SQLite数据库中读取数据
def select_db(sql):
    cursor = CONN.cursor()          # 该例程创建一个 cursor，将在 Python 数据库编程中用到。
    CONN.row_factory = sqlite3.Row  # 可访问列信息
    cursor.execute(sql)             # 该例程执行一个 SQL 语句
    rows = cursor.fetchall()        # 该例程获取查询结果集中所有（剩余）的行，返回一个列表。
    return rows                     # print(rows[0][2]) # 选择某一列数据


# 取得现在时间
def get_now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


# 以数据库时间格式输出
def db_time(timestamp):
    if len(str(timestamp)) == 13:
        timestamp = timestamp//1000
    date_time = datetime.fromtimestamp(timestamp)
    return date_time.strftime("%Y-%m-%d %H:%M:%S")


# 以数据库时间格式输出
def to_t(input_time):
    return input_time.strftime("%Y-%m-%d %H:%M:%S")


# 取得交易列表开始读取时间
def get_time_line():
    with open(PARAMS, 'r') as fread:
        arr = fread.read().strip().split(' ')
        return arr[9]+' '+arr[10]


# 扣除交易所手续费率
def fees_rate():
    return 1-0.002


# 比市价多多少比例买入
def buy_price_rate():
    return 1.0003


# 比市价少多少比例卖出
def sell_price_rate():
    return 0.99998


# 取得比特币当前报价
def get_price_now():
    try:
        return float(get_kline('btcusdt', '1min', 1)['data'][0]['close'])
    except:
        return 0


# 美元兑换人民币汇率
def usd2cny():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'CNY'")
    return round(data[0][0], 4)


# 泰达币兑换美元汇率
def usdt2usd():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'USDT'")
    return round(1/data[0][0], 4)


# 泰达币兑换人民币汇率
def usdt2cny():
    return usd2cny()*usdt2usd()


# 执行下单操作
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


# 撤消所有下单
def clear_orders():
    try:
        root = cancel_open_orders(ACCOUNT_ID, 'btcusdt')
        if root["status"] == "ok":
            return 'All open orders cleared'
    except:
        return 'Some error happened'


# 获得可交易的泰达币总数
def get_trade_usdt():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'usdt' and item['type'] == 'trade':
                return float(item['balance'])
                break
    except:
        return '0'


# 获得可交易的比特币总数
def get_trade_btc():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'btc' and item['type'] == 'trade':
                return float(item['balance'])
                break
    except:
        return 0


# 获得交易所中所有比特币的总数
def get_total_btc():
    try:
        amount = 0
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'btc':
                amount += float(item['balance'])
        return amount
    except:
        return 0


# 获得数据库中比特币的总数
def get_all_btc_amount():
    rows = select_db("SELECT sum(amount) FROM properties WHERE currency_id = 6")
    return rows[0][0]


# 获得交易列表中未卖出的平均成交价格
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


# 若下单的金额小于所设定的最小金额(比如5USDT)则将下单的数量加以调整，否则下单会失败
def check_sell_min_amount(price, amount):
    global MIN_SELL_USDT
    if float(price)*float(amount) <= MIN_SELL_USDT:
        return MIN_SELL_USDT/float(price)
    else:
        return amount


# 处理下单的主要流程
def place_order_process(test_price, price, amount, deal_type, ftext, time_line, u2c):
    global below_price
    global buy_price_period
    global sell_price_period
    global buy_period_move
    global WAIT_SEND_SEC
    global ALREADY_SEND_BUY
    # 验证下单数量是否高于或等于最小下单数
    amount = check_sell_min_amount(price, amount)
    # 如果不是测试单而是实际送单
    if test_price == 0:
        # 如果是卖单或是未重复的买单
        if deal_type.find('sell-limit') > -1 or ALREADY_SEND_BUY == False:
            # 执行下单操作并显示下单成功的下单号或下单失败讯息
            str = place_new_order("%.2f" % price, "%.6f" % amount, deal_type)
            print(str)
            ftext += str+'\n'
            # 停留几秒以等待下单成交结果
            time.sleep(WAIT_SEND_SEC)
            # 如果是买单
            if deal_type.find('buy-limit') > -1:
                # 获得交易所回传的成交结果并新增n笔交易记录
                n_dl_added = update_huobi_deal_records(time_line)
                # n=0表示买单未成交
                if n_dl_added == 0:
                    # 避免未成交时再重复送单造成资金的浪费
                    ALREADY_SEND_BUY = True
                # 显示新增n笔交易记录
                str = "%i Deal Records added" % n_dl_added
                print(str)
                ftext += str+'\n'
            # 获得可交易的USDT
            trade_usdt = float(get_trade_usdt())
            # 如果有剩余的USDT
            if trade_usdt > 0:
                # 显示目前USDT的剩余数量
                usdt_cny = trade_usdt*u2c
                str = "USDT Trade Now: %.4f (%.2f CNY)" % (
                    trade_usdt, usdt_cny)
                print(str)
                ftext += str+'\n'
                # 获得可交易的BTC
                trade_btc = float(get_trade_btc())
                # 显示目前BTC的剩余数量与持仓水平
                btc_cny = trade_btc*price*u2c
                btc_level_now = btc_hold_level(price)
                str = "BTC Now: %.8f (%.1f CNY) Total: %.1f CNY Level: %.2f%%" % (
                    trade_btc, btc_cny, usdt_cny+btc_cny, btc_level_now)
                print(str)
                ftext += str+'\n'
                # 如果设定了'买入几分钟内的最低价'及'仓位越高买入周期越长'
                if buy_price_period > 0 and buy_period_move > 0:
                    # 设置新的'买入几分钟内的最低价'的值
                    new_buy_price_period = int(btc_level_now/buy_period_move)
                    # 如果'买入几分钟内的最低价'的值小于2则以2计算
                    if new_buy_price_period < 2:
                        new_buy_price_period = 2
                    # 更新'买入几分钟内的最低价'的设定文档及在内存中的值
                    update_buy_price_period(new_buy_price_period)
                    buy_price_period = new_buy_price_period
                    # 显示'买入几分钟内的最低价'的值已更新
                    str = "Minimum Price Period Updated to: %i Minutes" % new_buy_price_period
                    print(str)
                    ftext += str+'\n'
                # 更新火币交易所的资产现况并显示
                str = "%i Huobi Assets Updated, Send Order Process Completed" % update_all_huobi_assets()
                print(str)
                ftext += str+'\n'
                # 如果可交易的比特币数量超过买入比特币的最大总值则显示操作暂停
                if trade_btc > target_amount:
                    str = "Already reach target amount, Invest PAUSE!"
                    print(str)
                    ftext += str+'\n'
        # 如果是重复发送的买单
        else:
            # 显示已重复发送
            str = "Already send order before, check if can send next order..."
            print(str)
            ftext += str+'\n'
            # 等待一段时间再向交易所获取最新成交情况
            time.sleep(WAIT_SEND_SEC*2)
            n_dl_added = update_huobi_deal_records(time_line)
            # 如果已成交则重置ALREADY_SEND_BUY
            if n_dl_added > 0:
                ALREADY_SEND_BUY = False
    # 如果是测试单
    else:
        # 显示测试单的各项数据
        str = "Sim Order Price: %.2f, Amount: %.6f, Type: %s" % (price, amount, deal_type)
        print(str)
        ftext += str+'\n'
        sim_btc_level, sim_ave_price = cal_sim_btc_level(price, amount)
        str = "Sim BTC Level: %.2f%%(+%.2f%%), Ave: %.2f" % (sim_btc_level, sim_btc_level-btc_hold_level(price), sim_ave_price)
        print(str)
        ftext += str+'\n'
    # 返回欲显示的输出文字
    return ftext


# 计算测试单的仓位水平
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


# 清空所有未卖出的交易记录
def clear_deal_records():
    global acc_id
    sql = "DELETE FROM deal_records WHERE account = '%s' and auto_sell = 0" % acc_id
    CONN.execute(sql)
    CONN.commit()


# 更新设定文档中的'更新交易列表记录日期'与'更新交易列表记录时间'
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


# 更新设定文档中的'多少价位以下执行买入'
def update_below_price(new_below_price):
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[1] = str(new_below_price)
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        # 定价的策略和买最低价的策略无法并存
        if new_below_price > 0:
            update_buy_price_period(0)
        return 1
    except:
        return 0


# 更新设定文档中的'买入几分钟内的最低价'
def update_buy_price_period(new_value):
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[17] = str(new_value)
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        # 定价的策略和买最低价的策略无法并存
        if new_value > 0:
            update_below_price(0)
        return 1
    except:
        return 0


# 更新设定文档中的'是否强制执行停损卖出'
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


# 重置设定文档中的'是否强制执行停损卖出'
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


# 重置设定文档中的'用于测试的比特币价格'
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


# 计算比特币目前的持有仓位
def btc_hold_level(price):
    amounts = {'usdt': 0, 'btc': 0}
    for item in get_balance(ACCOUNT_ID)['data']['list']:
        for currency in ['usdt', 'btc']:
            if item['currency'] == currency:
                amounts[currency] += float(item['balance'])
    btc_usdt = price*amounts['btc']
    usdt = amounts['usdt']
    return btc_usdt/(btc_usdt+usdt)*100


# 显示下一次执行的时间
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


# 由下单回传值计算正确的获利值
def sell_profit_cny_from_order(order_id, cost_usdt_total):
    data = order_info(order_id)['data']
    field_cash_amount = float(data['field-cash-amount'])
    field_fees = float(data['field-fees'])
    field_amount = float(data['field-amount'])
    profit_usdt = field_cash_amount - field_fees - cost_usdt_total
    profit_cny = profit_usdt*usdt2cny()
    return profit_cny, field_amount, field_fees


# 执行卖出下单的主要流程
def batch_sell_process(test_price, price, base_price, ftext, time_line, u2c, profit_goal, max_sell_count):
    global ORDER_ID     # 下单回传编号
    global FORCE_SELL   # 是否执行强制卖出
    global acc_id       # 交易所识别账号
    # 单次获利最多卖出笔数>0才能执行卖出
    if max_sell_count > 0:
        # 读取未卖交易记录
        rows = select_db(
            "SELECT id, amount - fees as amount, created_at, price FROM deal_records WHERE account = '%s' and auto_sell = 0 ORDER BY first_sell DESC, price ASC LIMIT %i" % (acc_id, max_sell_count))
        len_rows = len(rows)
        # 如果有未卖的交易记录
        if len_rows > 0:
            ids = []                # 存放数据ID
            sell_amount = 0         # 卖出的总量
            sell_count = 0          # 笔数计数器
            sell_profit_total = 0   # 卖出的总获利
            cost_usdt_total = 0     # 购买的总成本
            cost_price_ave = 0      # 购买的均价
            created_at = ''         # 购买时间
            # 下单的卖出价比市价稍低以争取快速成交
            sell_price = round(price*sell_price_rate(), 2)
            # 逐笔迭代累计上述的值
            for row in rows:
                id = row[0]         # 数据ID
                amount = row[1]     # 扣除手续费后的成交量(实际得到的量)
                created_at = row[2] # 下单的时间
                cost_price = row[3] # 下单成交价
                # 累加数据ID
                ids.append(id)
                # 累加计数器
                sell_count += 1
                # 累加卖出的总获利
                sell_profit_total += (sell_price-cost_price)*amount*fees_rate()*u2c
                # 累加卖出的总量
                sell_amount += amount
                # 累加购买的总成本
                cost_usdt_total += cost_price*amount
                # 计算成交均价
                cost_price_ave = round(cost_usdt_total/sell_amount, 2)
                # 如果还没有累加完则继续累加
                if len_rows >= max_sell_count and sell_count != max_sell_count:
                    continue
                else:
                    if sell_count == max_sell_count:
                        # 提交卖出订单
                        ftext = place_order_process(test_price, sell_price, sell_amount, \
                        'sell-limit', ftext, time_line, u2c)
                        # 如果提交成功，将这些交易记录标示为已自动卖出并更新下单编号及已实现损益
                        if test_price == 0 and len(ORDER_ID) > 0:
                            # 获取现在时间
                            time_now = get_now()
                            # 由订单回传的实际值计算已实现损益并获取卖出的成交量及手续费
                            real_profit, real_sell_amount, real_sell_fees = sell_profit_cny_from_order(ORDER_ID,cost_usdt_total)
                            # 将最近一笔的交易记录更新为卖出记录并更新相关栏位值
                            sql = "UPDATE deal_records SET auto_sell = 1, order_id = '%s', price = %.2f, amount = %.6f, fees = %.9f, real_profit = %.6f, updated_at = '%s' WHERE id = %i" % (
                                ORDER_ID, cost_price_ave, real_sell_amount, real_sell_fees, real_profit, time_now, ids[-1])
                            CONN.execute(sql)
                            CONN.commit()
                            # 删除无用的交易记录
                            for id in ids[0:-1]:
                                sql = "DELETE FROM deal_records WHERE id = %i" % id
                                CONN.execute(sql)
                                CONN.commit()
                            # 重置交易单号
                            ORDER_ID = ''
                            # 显示处理的讯息
                            str = "%i Deal Records Auto Sold and Combined, Sold Profit: %.4f CNY" % (
                                len(ids), real_profit)
                            print(str)
                            ftext += str+'\n'
                            # 更新记录time_line文档以避免更新交易记录时重头读取浪费时间
                            update_time_line(time_now)
                            str = "Time Line Updated to: %s And Clear Records!" % time_now
                            print(str)
                            ftext += str+'\n'
                        else:
                            # 显示测试单的输出
                            str = "Sim Update %i Deal Records with Profit: %.2f CNY" % (
                                len(ids), sell_profit_total)
                            print(str)
                            ftext += str+'\n'
                        break
    # 如果单次获利最多卖出笔数不大于0表示不允许卖出
    else:
        # 显示无法卖出的原因
        str = "Stop Sell Because Max Sell Count = 0"
        print(str)
        ftext += str+'\n'
    # 返回所有要输出的讯息
    return ftext


# 返回在指定区间内(几分钟内)比特币价格的最大值与最小值
def get_min_max_price(buy_price_period, sell_price_period):
    try:
        # 几分钟内比特币价格的最小值
        arr = []
        if buy_price_period == 0:
            buy_price_period = 1
        root = get_huobi_price('btcusdt', '1min', buy_price_period)
        for data in root["data"]:
            arr.append(data["low"])
        min_price = min(arr)
        # 几分钟内比特币价格的最大值
        arr = []
        if sell_price_period == 0:
            sell_price_period = 1
        root = get_huobi_price('btcusdt', '1min', sell_price_period)
        for data in root["data"]:
            arr.append(data["high"])
        max_price = max(arr)
        # 返回最小值与最大值
        return [min_price, max_price]
    except:
        # 如发生异常则返回0
        return [0, 0]


# 求解买入几分钟内的最低价，返回现价、最低价、是否已达到触发条件，idx为触底反弹买进的索引值
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


# 求解卖出几分钟内的最高价，返回现价、最高价、是否已达到触发条件
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


# 重置强制买卖
def reset_force_trade():
    global ORDER_ID
    global FORCE_BUY
    global FORCE_SELL
    ORDER_ID = ''
    FORCE_BUY = False
    FORCE_SELL = False


# 回传最近一笔买单的间隔秒数，若无则回传最近一笔卖单的间隔秒数
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


# 回传最近一笔卖单的间隔秒数，若无则回传一个很大的数字
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


# 计算最初几笔未卖出交易记录的损益值(¥)
def top_n_profit(sell_price):
    global acc_id
    global max_sell_count
    rows = select_db("SELECT amount - fees as amount, price FROM deal_records WHERE account = '%s' and auto_sell = 0 ORDER BY first_sell DESC, price ASC LIMIT %i" % (acc_id, max_sell_count))
    if len(rows) > 0:
        sell_profit_total = 0
        fr = fees_rate()
        u2c = usdt2cny()
        for row in rows:
            amount = row[0]
            cost_price = row[1]
            sell_profit_total += (sell_price-cost_price)*amount*fr*u2c
        return sell_profit_total
    else:
        return 0


# 执行自动下单的主程序
def exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt, factor, max_buy_level, target_amount, min_usdt, max_rate, time_line, test_price, profit_goal, max_sell_count, min_sec_rate, max_sec_rate):
    # 引用全域变数
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
    global stop_sell_level
    # 写入Log文档
    with open(LOG_FILE, 'a') as fobj:
        # Log分隔符
        sline = LINE_MARKS
        ftext = sline+'\n'
        # 以日期与时间开始Log讯息
        now = datetime.now()
        if below_price > 0:
            str = "%s Invest Between: %.2f ~ %.2f %s %s" % (get_now(), bottom_price, below_price, acc_id, ACCOUNT_ID)
        else:
            str = "%s Invest Between: %.2f ~ AUTO" % (get_now(), bottom_price)
        print(str)
        ftext += str+'\n'
        # 获得现价与汇率值
        price_now = get_price_now()
        u2c = usdt2cny()
        if price_now > 0:
            # 显示现价与价格幅度
            amplitude = 0
            if min_price > 0 and max_price > 0:
                amplitude = (max_price-min_price)/min_price*100
            if test_price > 0:
                str = "Test Price: %.2f Now: %.2f %i_Min: %.2f %i_Max: %.2f(%.2f%%)" % (test_price, price_now, buy_price_period, min_price, sell_price_period, max_price, amplitude )
                price_now = test_price
                str += '\n' + ("Price Now Update to: %.2f" % price_now)
            else:
                str = "Price Now: %.2f %i_Min: %.2f %i_Max: %.2f(%.2f%%)" % (price_now, buy_price_period, min_price, sell_price_period, max_price, amplitude )
            print(str)
            ftext += str+'\n'
            # 若为买单或测试单
            if FORCE_BUY == True or test_price > 0:
                # 原有参与投资的USDT
                ori_usdt = float(ori_usdt)
                # 获得实际能交易的USDT
                trade_usdt = float(get_trade_usdt())
                # 跌破多少价位停止买入
                bottom = float(bottom_price)
                # 单笔买入的最大值
                max_usdt = ori_usdt*max_rate
                # 计算BTC目前持仓水平
                btc_level_now = btc_hold_level(price_now)
                # 如果是测试单 或者 实际能交易的USDT>单笔买入的最小值 以及 现价必须>最低购买价
                if test_price > 0 or \
                    (trade_usdt > min_usdt and price_now - bottom >= 0):
                    # 计算购买成本与购买数量
                    price_diff = price_now - bottom
                    if price_now - bottom < 1:
                        price_diff = 1
                    usdt = (ori_usdt/((price_diff)/100)**2)*factor
                    # 设定好边界条件的值
                    if usdt < min_usdt:
                        usdt = min_usdt
                    if usdt > max_usdt:
                        usdt = max_usdt
                    # 如果超出预算则买入剩余USDT取整
                    if usdt > trade_usdt:
                        usdt = int(trade_usdt)
                    else:
                        usdt = round(usdt, 2)
                    # 由预算计算出要购买的数量
                    amount = usdt/price_now
                    # 计算还能持续买多久
                    min_sec = every_sec*min_sec_rate
                    new_sec = min_sec + every_sec*(max_sec_rate-min_sec_rate) * \
                        ((price_now-bottom_price)/(below_price-bottom_price))
                    every_sec = int(new_sec)
                    remain_hours = float(trade_usdt/usdt*every_sec/3600)
                    delta_hours = timedelta(hours=remain_hours)
                    empty_usdt_time = to_t(now + delta_hours)
                    usdt_cny = trade_usdt*u2c
                    # 显示所有相关购买讯息
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
                    str = "Buy Amount: %.6f BTC (%.2f CNY)" % (amount, amount*price_now*u2c)
                    print(str)
                    ftext += str+'\n'
                    str = "Get Amount: %.8f BTC (%.2f CNY)" % (amount*fees_rate(), amount*price_now*u2c)
                    print(str)
                    ftext += str+'\n'
                    # 显示下一次执行时间
                    ftext = print_next_exe_time(every_sec, ftext)
                    str = "Zero Time: %s (%.2f H | %.2f D)" % (
                        empty_usdt_time, remain_hours, remain_hours/24)
                    print(str)
                    ftext += str+'\n'
                    # 执行买单的委托并显示回传的讯息
                    ftext = place_order_process(
                        test_price, round(price_now*buy_price_rate(), 2), amount, 'buy-limit', ftext, time_line, u2c)
                    fobj.write(ftext)
                    return every_sec
                # 不是测试单也不符合买单条件
                else:
                    return every_sec
            # 若为卖单
            elif FORCE_SELL == True:
                ftext = batch_sell_process(0, price_now, below_price, ftext, time_line, \
                        u2c, -100000, max_sell_count)
                fobj.write(ftext)
                return every_sec
            else:
                return every_sec
        else:
            # 无法读取现价，等待3秒后重新执行一遍
            return 3


# 显示讯息到控制台
def stdout_write( message ):
    sys.stdout.write("\r")
    sys.stdout.write(message)
    sys.stdout.write("\n")


########## 自定义函数结束 ##################################################################


# 脚本主函数
if __name__ == '__main__':
    # 载入火币账号ID及API密钥
    load_api_key()
    # 无限循环直到按下Ctrl+C终止
    while True:
        # 正常运行的情况
        try:
            # 打开参数设定文档
            with open(PARAMS, 'r') as fread:
                # 将设定文档参数读入内存
                params_str = fread.read().strip()
                every_sec, below_price, bottom_price, ori_usdt, factor, max_buy_level, target_amount, min_usdt, max_rate, deal_date, deal_time, test_price, profit_goal, max_sell_count, min_sec_rate, max_sec_rate, detect_sec, buy_price_period, sell_price_period, buy_period_move, force_to_sell, min_price_index, every_sec_for_sell, sell_max_cny, acc_id, deal_cost, deal_amount, force_sell_price, acc_real_profit, stop_sell_level = \
                params_str.split(' ')
                # 将设定文档参数根据适当的型别初始化
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
                profit_goal = float(profit_goal)
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
                force_sell_price = float(force_sell_price)
                stop_sell_level = float(stop_sell_level)
                # 获得在几分钟内比特币价格的最大值与最小值
                min_price, max_price = get_min_max_price(buy_price_period, sell_price_period)
                # 是否执行强制卖出
                if force_to_sell > 0:
                    FORCE_SELL = True
                # 执行自动下单的主程序
                code = exe_auto_invest(every_sec, below_price, bottom_price, ori_usdt,
                                       factor, max_buy_level, target_amount, min_usdt, max_rate, time_line, test_price, profit_goal, max_sell_count, min_sec_rate, max_sec_rate)
                # 清零与重载：测试单、强制卖出、强制买卖、火币账号
                reset_test_price()
                reset_force_sell()
                reset_force_trade()
                load_api_key()
                # 如果返回0则结束程序
                if code == 0:
                    break
                else:
                    # 每隔几秒侦测参数变化并显示可否买卖讯息
                    for remaining in range(int(code), 0, -1):
                        sys.stdout.write("\r")
                        sys.stdout.write("********** %i seconds for next operate **********" % remaining)
                        sys.stdout.flush()
                        time.sleep(1)
                        if remaining % detect_sec == 0:
                            # 如果间隔秒数发生变化则跳出回圈重新执行主程序
                            with open(PARAMS, 'r') as f:
                                line_str = f.read().strip()
                                if line_str[0:5] != params_str[0:5]:
                                    break
                            ###############################################################
                            # 现价、最高价、是否已达到卖价
                            price_now, max_price, over_max_price = max_price_in(sell_price_period)
                            # BTC目前的仓位值
                            btc_level_now = btc_hold_level(price_now)
                            # 是否达到可买入的时间
                            over_buy_time = last_buy_interval() > every_sec
                            # 是否达到可卖出的时间
                            over_sell_time = last_sell_interval() > every_sec_for_sell
                            # 是否在可买入的价格之下
                            is_below_price = price_now > 0 and price_now < below_price
                            # 是否在可卖出的价格之上
                            is_above_price = price_now > 0 and force_sell_price > 0 and price_now >= force_sell_price
                            # 是否达到分钟内的最高价
                            reach_high_price = sell_price_period > 0 and over_max_price
                            # 是否在可买入的仓位之下
                            below_buy_level = max_buy_level > 0 and btc_level_now < max_buy_level
                            # 是否在可卖出的仓位之上
                            over_sell_level = max_sell_count > 0 and btc_level_now > stop_sell_level
                            # 是否达到了设定的最小获利值，如未达到则不卖出
                            if profit_goal > 0:
                                if top_n_profit(price_now) >= profit_goal:
                                    over_sell_profit = True
                                else:
                                    over_sell_profit = False
                            else:
                                over_sell_profit = True
                            #################################################################
                            # 达到卖出的条件则执行卖出(仓位、时间、获利、[可卖价格之上|分钟内的最高价])
                            if over_sell_level and over_sell_time and over_sell_profit and \
                                (is_above_price or reach_high_price):
                                setup_force_sell()
                                break
                            #################################################################
                            # 达到买入的条件则执行买入
                            if price_now > 0 and below_price > 0:
                                stdout_write("%s | now: %.2f below_price: %i sell_price: %i buy_time: %s sell_time: %s                " % (acc_id, price_now, below_price, force_sell_price, over_buy_time, over_sell_time))
                                # 买入条件：仓位、时间、在可买入的价格之下
                                if below_buy_level and over_buy_time and is_below_price:
                                    FORCE_BUY = True
                                    break
                            #################################################################
                            # 达到买入的条件则执行买入
                            if buy_price_period > 0:
                                # 现价、最低价、是否达到分钟内的最低价
                                price_now, min_price, reach_low_price = min_price_in(min_price_index, buy_price_period)
                                if price_now > 0 and min_price > 0:
                                    stdout_write("%s | now: %.2f %im_min: %i  sell_price: %i buy_time: %s sell_time: %s                " % (acc_id, price_now, buy_price_period, min_price, force_sell_price, over_buy_time, over_sell_time))
                                    # 买入条件：仓位、时间、达到分钟内的最低价
                                    if below_buy_level and over_buy_time and reach_low_price:
                                        FORCE_BUY = True
                                        break
                            ################################################################
                            if price_now > 0 and max_price > 0 and sell_price_period > 0:
                                stdout_write("%s | now: %.2f %im_max: %i  sell_price: %i buy_time: %s sell_time: %s              " % (acc_id, price_now, sell_price_period, max_price, force_sell_price, over_buy_time, over_sell_time))
                            ################################################################
                    stdout_write(" "*30)
        except:
            print("Some Unexpected Error, Please Break Program to check!!")
            time.sleep(3600)