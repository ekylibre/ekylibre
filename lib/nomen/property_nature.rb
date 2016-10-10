module Nomen
  class PropertyNature
    attr_reader :nomenclature, :name, :type, :fallbacks, :default, :source

    # New item
    def initialize(nomenclature, name, type, options = {})
      @nomenclature = nomenclature
      @name = name.to_sym
      @type = type
      raise "Invalid type: #{@type.inspect}" unless Nomen::PROPERTY_TYPES.include?(@type)
      @fallbacks = options[:fallbacks] if options[:fallbacks]
      @default = options[:default] if options[:default]
      @required = !!options[:required]
      @source = options[:choices] if reference? && options[:choices]
    end

    Nomen::PROPERTY_TYPES.each do |type|
      define_method "#{type}?" do
        @type == type
      end
    end

    def to_xml_attrs
      attrs = {}
      attrs[:name] = @name.to_s
      attrs[:type] = @type.to_s
      if @source
        attrs[:choices] = if inline_choices?
                            @source.join(', ')
                          else
                            @source.to_s
                          end
      end
      attrs[:required] = 'true' if @required
      attrs[:fallbacks] = @fallbacks.join(', ') if @fallbacks
      attrs[:default] = @default.to_s if @default
      attrs
    end

    # Returns if property is required
    def required?
      @required
    end

    def inline_choices?
      choice? || choice_list?
    end

    def item_reference?
      item? || item_list?
    end

    def reference?
      choice_list? || item_list? || string_list? || choice? || item?
    end

    def list?
      choice_list? || item_list? || string_list?
    end

    def choices_nomenclature
      @source
    end

    # Returns list of choices for a given property
    def choices
      if inline_choices?
        return @source || []
      elsif item_reference?
        return @nomenclature.sibling(@source).all.map(&:to_sym)
      end
    end

    def selection
      if inline_choices?
        return choices.collect do |c|
          ["nomenclatures.#{@nomenclature.name}.choices.#{name}.#{c}".t, c]
        end
      elsif item_reference?
        return @nomenclature.sibling(@source).selection
      end
    end

    # Return human name of property
    def human_name
      "nomenclatures.#{nomenclature.name}.property_natures.#{name}".t(default: ["nomenclatures.#{nomenclature.name}.properties.#{name}".to_sym, "properties.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize])
    end

    alias humanize human_name

    def <=>(other)
      name <=> other.name
    end
  end
end
