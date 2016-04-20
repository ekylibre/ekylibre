module Nomen
  class Relation < Array
    attr_reader :nomenclature
    
    alias find_each each

    def initialize(nomenclature, *args)
      super(*args)
      @nomenclature = nomenclature
    end

    %w(select collect detect).each do |meth|
      define_method meth do |*args, &block|
        self.class.new(@nomenclature, super(*args, &block))
      end
    end

    def selection
      collect do |item|
        [item.human_name, item.name.to_s]
      end.sort do |a, b|
        a.first.lower_ascii <=> b.first.lower_ascii
      end
    end
  end
end
