module Accountancy
  class Period
    attr_reader :start, :stop, :days

    def initialize(start, stop)
      @start, @stop = [start, stop].sort
      @days = Duration.diff start, stop
    end

    def split(date)
      if start <= date && date < stop
        [Period.new(start, date), Period.new(date + 1.day, stop)]
      else
        [self]
      end
    end
  end
end