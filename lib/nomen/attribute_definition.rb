module Nomen

  class AttributeDefinition
    attr_reader :nomenclature, :name, :type, :fallbacks, :default

    TYPES = [:boolean, :choice, :date, :decimal, :integer, :list, :string]

    # New item
    def initialize(nomenclature, element, options = {})
      @nomenclature = nomenclature
      @name = element.attr("name").to_sym
      @type = element.attr("type").to_sym
      if element.has_attribute?("fallbacks")
        @fallbacks = element.attr("fallbacks").to_s.strip.split(/[\s\,]+/).map(&:to_sym)
      end
      if element.has_attribute?("default")
        @default  = element.attr("default").to_s
      end
      @required = !!(element.attr("required").to_s == "true")
      @inherit  = !!(element.attr("inherit").to_s == "true")
      raise ArgumentError.new("Attribute #{@name} type is unknown") unless TYPES.include?(@type)
      if @type == :choice or @type == :list
        if element.has_attribute?("choices")
          @choices = element.attr("choices").to_s.strip.split(/[\,\s]+/).map(&:to_sym)
        elsif element.has_attribute?("nomenclature")
          @choices = element.attr("nomenclature").to_s.strip.to_sym
        elsif @type != :list
          raise ArgumentError.new("[#{@nomenclature.name}] Attribute #{@name} must have choices or nomenclature attribute")
        end
      end
    end

    # Returns if attribute is required
    def required?
      @required
    end

    # Returns if attribute is required
    def inherit?
      @inherit
    end

    def inline_choices?
      !@choices.is_a?(Symbol)
    end

   def choices_nomenclature
      @choices
    end

    # Returns list of choices for a given attribute
    def choices
      if inline_choices?
        return @choices || []
      else
        return Nomen[@choices.to_s].all
      end
    end

    # Return human name of attribute
    def human_name
      "nomenclatures.#{nomenclature.name}.attributes.#{name}".t(:default => ["attributes.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize])
    end
    alias :humanize :human_name

  end

end
