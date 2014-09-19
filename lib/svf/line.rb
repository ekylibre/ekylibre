module SVF

  class Line
    attr_reader :name, :key, :cells, :children, :to

    def initialize(name, key, cells, children=[], to=nil)
      @name = name.to_sym
      @key = key
      @cells = [] # ActiveSupport::OrderedHash.new
      for cell in cells
        for name, definition in cell
          unless c = Cell.new(name, definition, @key.length+@cells.inject(0){|s,c| s += c.length})
            raise "Element #{@name} has an cell #{name} with no definition"
          end
          @cells << c
        end
      end if cells
      @children = SVF.occurrencify(children||[])
      @to = to
    end

    def class_name(prefix=nil)
      if prefix.nil?
        @name.to_s.classify
      else
        "SVF::#{prefix.to_s.classify}::Lines::#{self.class_name}"
      end
    end

    def inspect
      i = "#{self.name}(#{self.key}) #{@cells.inspect}"
      i << "\n"+@children.collect{|c| c.inspect.gsub(/^/, '  ')}.join("\n") if @children.size > 0
      return i
    end

    def has_cells?
      return !@cells.size.zero?
    end

    def has_children?
      return !@children.size.zero?
    end

  end

end
