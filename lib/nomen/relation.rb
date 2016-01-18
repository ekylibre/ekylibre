module Nomen
  class Relation < Array
    alias find_each each

    def select(*args, &block)
      self.class.new(super(*args, &block))
    end
  end
end
