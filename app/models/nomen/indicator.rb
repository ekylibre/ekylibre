module Nomen
  class Indicator < Nomen::Record::Base
    class << self
      delegate :each, to: :all
    end
  end
end
