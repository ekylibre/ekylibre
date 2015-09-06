class ProductJunction
  # This class permit to store a junction reflection
  class Reflection
    attr_reader :macro, :name, :type
    def initialize(macro, name, options = {})
      @macro = macro.to_sym
      @name = name.to_sym
      @type = (options[:as] || :continuity).to_sym
      fail "Invalid type: #{@type.inspect}" unless ProductJunctionWay.nature.values.include?(@type)
    end
  end
end
