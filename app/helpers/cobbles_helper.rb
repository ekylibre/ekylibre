module CobblesHelper

  class Cobble
    attr_reader :name, :block, :id, :title
    def initialize(cobbler, name, options = {}, &block)
      @cobbler = cobbler
      @name = name
      @id = options[:id] || name.to_s.parameterize.dasherize
      @title = options[:title] || @name.tl
      @block = block
    end

    def others
      @cobbler.items.select{|c| c.id != @id }
    end
  end

  class Cobbler
    attr_reader :items

    def initialize
      @items = []
    end

    def cobble(name, options = {}, &block)
      if @items.detect{|i| i.name.to_s == name.to_s }
        raise "Already taken. You already use #{name.inspect}"
      end
      @items << Cobble.new(self, name, options, &block)
    end

    def any?
      @items.any?
    end

    def each(&block)
      @items.each(&block)
    end

  end

  # Cobbles are a simple layout with all cobble in one list.
  # List is sortable and cobbles are hideable/collapseable
  def cobbles(&block)
    cobbler = Cobbler.new
    yield cobbler
    if cobbler.any?
      render "cobbles", cobbler: cobbler
    end
  end


end
