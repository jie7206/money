require 'net/http'

# 每隔若干秒自动执行网页一次
period = 60*20
puts "Auto update all data every #{period} seconds, go to console in playruby.top:3004 to view output or press Ctrl+C to exit..."
while true
  Net::HTTP.get_response(URI('http://playruby.top:3004/update_all_data'))
  sleep period
end
