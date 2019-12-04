require "uri"
require "net/http"

uri = URI.parse("http://api.huobi.pro/market/history/kline?period=1min&size=1&symbol=btcusdt")
p Regexp.new(/close\":(\d+)\.(\d+)/).match(Net::HTTP.get_response(uri).body).to_a[0].split(':')[1].to_f.floor(2)
