import requests
import time
import json


class RequessTest(object):
    def __init__(self, url):
        self.url = url
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.108 Safari/537',
            'Content-Type': 'application/json; charset=UTF-8',
            'Cookie': 'MicrosoftApplicationsTelemetryDeviceId=d6d978fd-7d4a-51bb-a56c-e9d01087265c; MicrosoftApplicationsTelemetryFirstLaunchTime=1514433998658; srcLang=-; smru_list=; sourceDia=en-US; destLang=zh-CHS; dmru_list=da%2Czh-CHS; destDia=zh-CN; mtstkn=EKimUInV29dbd91DCr7IzX80X6hVOI9Sk%252FHwx5ee4wudngq85T%252FMaSJeXCBtQJsJ; _EDGE_S=F=1&SID=2F7A08541C8762552CCA03321D306369; _EDGE_V=1; MUID=17658D2AD0B3658A0691864CD104645E; MUIDB=17658D2AD0B3658A0691864CD104645E; SRCHHPGUSR=WTS=63650030798; SRCHD=AF=NOFORM; SRCHUID=V=2&GUID=393B99CACB9E453BA91A92659B1DA288&dmnchg=1; SRCHUSR=DOB=20171228; _SS=SID=2F7A08541C8762552CCA03321D306369'

        }
        self.proxy = {
            'http': '219.149.59.250:9797'
        }
    # get请求方法

    def request_get(self):
        data = {
            'wd': '日本'
        }
        r = requests.get(url=self.url, params=data, headers=self.headers)

        print('hearders:', r.headers)
        time.sleep(3)

    # post请求方法方法
    def request_post(self):
        data = [{
            'id': '',
            'text': 'pig'
        }]
        r = requests.post(url=self.url, headers=self.headers, data=json.dumps(data))
        print(r.text)

    # 设置代理访问
    def request_proxy(self):
        data = {
            'wd': 'ip'
        }
        r = requests.get(url=self.url, headers=self.headers, params=data, proxies=self.proxy)
        print(r.text)


url1 = 'https://www.baidu.com/s'
# url2 = 'http://www.bing.com/translator/api/Translate/TranslateArray?from=-&to=zh-CHS'
# url = 'http://172.24.190.176:3001/btc_hold_level'

print(RequessTest(url1).request_get())
# RequessTest(url2).request_post()
# RequessTest(url1).request_proxy()
