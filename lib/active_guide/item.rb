module ActiveGuide

  class Item
    attr_reader :name, :before_block, :after_block, :accept_block

    def initialize(group, name, options = {})
      @group = group
      @name = name
      before(&options.delete(:before)) if options[:before].respond_to?(:call)
      after(&options.delete(:after)) if options[:after].respond_to?(:call)
      accept(&options.delete(:if)) if options[:if].respond_to?(:call)
    end

    def guide
      @group.guide
    end

    def accept(&block)
      raise "Missing block" unless block_given?
      @accept_block = block
    end

    def before(&block)
      raise "Missing block" unless block_given?
      @before_block = block
    end

    def after(&block)
      raise "Missing block" unless block_given?
      @after_block = block
    end

  end

end
