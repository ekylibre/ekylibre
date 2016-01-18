module ActiveGuide
  class Group < Item
    attr_reader :items

    def initialize(group, name, options = {}, &block)
      super group, name, options
      @items = []
      instance_eval(&block) if block_given?
    end

    def result(name, type = :numeric)
      add_item Result.new(self, name, type)
    end

    def group(name, options = {}, &block)
      add_item Group.new(self, name, options, &block)
    end

    def question(name, options = {}, &block)
      add_item Question.new(self, name, options, &block)
    end

    def test(name, *args, &block)
      options = args.extract_options!
      if block_given?
        add_item Test.new(self, name, options, &block)
      elsif (proc = args.shift) && proc.respond_to?(:call)
        add_item Test.new(self, name, options.merge(validate: proc))
      else
        fail "Cannot do anything with test #{name}"
      end
    end

    def add_item(item)
      unless item.is_a?(ActiveGuide::Item) || item.is_a?(ActiveGuide::Result)
        fail "Invalid item. Got #{item.inspect}:#{item.class.name}"
      end
      @items << item
    end
  end
end
