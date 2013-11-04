module Procedo

  class Variable
    attr_reader :name, :procedure, :value, :abilities, :variety, :derivative_of, :roles

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_sym
      @new = !element.attr("new").blank?
      @value = element.attr("value").to_s
      @abilities = element.attr("abilities").to_s.strip.split(/\s*\,\s*/)
      @variety = element.attr("variety").to_s.strip if element.has_attribute?("variety")
      # @variety = @variety.to_sym if @variety.is_a?(String) and @variety !=~ /\:/
      @derivative_of = element.attr("derivative-of").to_s.strip if element.has_attribute?("derivative-of")
      # @derivative_of = @derivative_of.to_sym if @derivative_of.is_a?(String) and @derivative_of !=~ /\:/
      @roles = element.attr("roles").to_s.strip.split(/\s*\,\s*/)
      @variant = element.attr("variant").to_s.strip if element.has_attribute?("variant")
    end

    def human_name
      "variables.#{name}".t(:default => ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize])
    end

    def given?
      !@value.blank?
    end

    def new?
      @new
    end

    def computed_variety
      if @variety
        if @variety =~ /\:/
          attr, other = @variety.split(/\:/)[0..1]
          attr = "variety" if attr.blank?
          attr.gsub!(/\-/, "_")
          return @procedure.variables[other].send("computed_#{attr}")
        else
          return @variety
        end
      end
      return nil
    end

    def computed_derivative_of
      if @derivative_of
        if @derivative_of =~ /\:/
          attr, other = @derivative_of.split(/\:/)[0..1]
          attr = "derivative_of" if attr.blank?
          attr.gsub!(/\-/, "_")
          return @procedure.variables[other].send("computed_#{attr}")
        else
          return @derivative_of
        end
      end
      return nil
    end

    # Returns scope hash for unroll
    def scope_hash
      hash = {}
      unless @abilities.empty?
        hash[:can] = @abilities.join(',')
      end
      hash[:of_variety] = computed_variety if computed_variety
      hash[:derivative_of] = computed_derivative_of if computed_derivative_of
      return hash
    end


    def known_variant?
      !@variant.nil?
    end

    def variant_variable
      if @variant =~ /\A\:/
        other = @variant[1..-1]
        return @procedure.variables[other]
      end
      return nil
    end

    def variant_indication
      if v = variant_variable
        return "same_variant_as_x".tl(x: v.human_name)
      end
      return "unknown_variant".tl
    end

  end

end
