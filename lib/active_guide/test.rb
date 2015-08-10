module ActiveGuide
  class Test < Item
    attr_reader :subtests, :validate_block

    def initialize(parent, name, options = {}, &block)
      super parent, name, options
      @subtests = []
      validate(&options.delete(:validate)) if options[:validate].respond_to?(:call)
      instance_eval(&block) if block_given?
    end

    def subtest?
      @subtests.any?
    end

    def validate?
      !subtest?
    end

    def subtest(name, *args, &block)
      if @validate_block.present?
        fail "Validation has been already defined in #{@name}"
      end
      options = args.extract_options!
      test = nil
      if block_given?
        test = Test.new(self, name, options, &block)
      elsif proc = args.shift and proc.respond_to? :call
        test = Test.new(self, name, options.merge(validate: proc))
      else
        fail "Cannot do anything with test #{name}"
      end
      @subtests << test
    end

    def validate(&block)
      fail "Sub-test has been already defined in #{@name}" if @subtests.any?
      @validate_block = block
    end
  end
end
