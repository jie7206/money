require 'net/http'

url = 'http://playruby.top:3004/update_all_data'
period = 60*15
puts "Auto update all data from #{url} every #{period} seconds."

while true
  begin
    Timeout.timeout(120) do
      puts "Run update_all_data at #{Time.now}"
      puts "#{Net::HTTP.get_response(URI(url))} finished at #{Time.now}"
    end
  rescue
    puts "Timeout error at #{Time.now}"
  end
  sleep period
end
