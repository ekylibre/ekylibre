module Nomen

  class PropertyNature
    attr_reader :nomenclature, :name, :type, :fallbacks, :default

    TYPES = [:boolean, :choice, :date, :decimal, :integer, :list, :nomenclature, :string, :symbol]

    # New item
    def initialize(nomenclature, element, options = {})
      @nomenclature = nomenclature
      @name = element.attr("name").to_sym
      @type = element.attr("type").to_sym
      if element.has_attribute?("fallbacks")
        @fallbacks = element.attr("fallbacks").to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
      end
      if element.has_attribute?("default")
        @default  = element.attr("default").to_sym
      end
      @required = !!(element.attr("required").to_s == "true")
      @inherit  = !!(element.attr("inherit").to_s == "true")
      unless TYPES.include?(@type)
        raise ArgumentError, "Property #{@name} type is unknown"
      end
      if @type == :choice or @type == :list
        if element.has_attribute?("choices")
          @choices = element.attr("choices").to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
        elsif element.has_attribute?("nomenclature")
          @choices = element.attr("nomenclature").to_s.strip.to_sym
        elsif @type != :list
          raise ArgumentError, "[#{@nomenclature.name}] Property #{@name} must have choices or nomenclature property"
        end
      end
    end

    # Returns if property is required
    def required?
      @required
    end

    # Returns if property is required
    def inherit?
      @inherit
    end

    def inline_choices?
      !@choices.is_a?(Symbol)
    end

   def choices_nomenclature
      @choices
    end

    # Returns list of choices for a given property
    def choices
      if inline_choices?
        return @choices || []
      else
        return Nomen[@choices.to_s].all.map(&:to_sym)
      end
    end

    def selection
      if inline_choices?
        return choices.collect do |c|
          [c, c]
        end
      else
        return Nomen[@choices.to_s].selection
      end
    end

    # Return human name of property
    def human_name
      "nomenclatures.#{nomenclature.name}.property_natures.#{name}".t(:default => ["nomenclatures.#{nomenclature.name}.properties.#{name}".to_sym, "properties.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize])
    end
    alias :humanize :human_name

  end

end
