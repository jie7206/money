require 'net/http'

url = 'http://playruby.top:3004/update_all_data'
period = 60*30
puts "Auto update all data from #{url} every #{period} seconds."

while true
  begin
    Timeout.timeout(300) do
      puts "Run update_all_data at #{Time.now}"
      puts Net::HTTP.get_response(URI(url))
    end
  rescue
    puts "Timeout error at #{Time.now}"
    next
  end
  sleep period
end
