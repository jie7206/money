class LineData < ApplicationRecord

  def self.find_repeat( symbol, period, tid )
    if find_by(symbol: symbol, period: period, tid: tid)
      return true
    else
      return false
    end
  end

end
