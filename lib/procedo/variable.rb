module Procedo

  class Variable
    attr_reader :name, :procedure, :value, :abilities, :variety, :derivative_of, :roles, :birth_nature, :genitor_name

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_sym
      if element.has_attribute?("new")
        @new_variable = true
        new = element.attr("new").to_s
        unless new.match(/\A(parted\-from|produced-by)\:/)
          raise StandardError, "The new variable #{@name} in procedure #{@procedure.name} must specify where does it comes from"
        end
        new_array = new.split(/\s*\:\s*/)
        @birth_nature  = new_array.shift.underscore.to_sym
        @genitor_name = new_array.shift.to_sym
      end
      @value = element.attr("value").to_s
      @abilities = element.attr("abilities").to_s.strip.split(/\s*\,\s*/)
      @variety = element.attr("variety").to_s.strip if element.has_attribute?("variety")
      # @variety = @variety.to_sym if @variety.is_a?(String) and @variety !=~ /\:/
      @derivative_of = element.attr("derivative-of").to_s.strip if element.has_attribute?("derivative-of")
      # @derivative_of = @derivative_of.to_sym if @derivative_of.is_a?(String) and @derivative_of !=~ /\:/
      @roles = element.attr("roles").to_s.strip.split(/\s*\,\s*/)
      if element.has_attribute?("variant")      
        if parted?
          raise StandardError, "'variant' attribute must be removed to limit ambiguity when new variable is parted from another"
        end
        @variant = element.attr("variant").to_s.strip
        if @variant =~ /\A\:/
          unless @procedure.variable_names.include?(@variant[1..-1].to_sym)
            raise StandardError, "Unknown variable for variant attribute: #{@variant}"
          end
        else
          unless Nomen::ProductNatureVariants[@variant]
            raise StandardError, "Unknown variant in product_nature_variants nomenclature: #{@variant}"
          end
        end
      end
    end


    # Returns the name of procedure (LOD)
    def procedure_name
      @procedure.name
    end

    # Translate the name of the variable
    def human_name
      "variables.#{name}".t(default: ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize])
    end

    # 
    def given?
      !@value.blank?
    end

    def new?
      @new_variable
    end

    def parted?
      new? and @birth_nature == :parted_from
    end

    def produced?
      new? and @birth_nature == :produced_by
    end

    def genitor
      @genitor ||= self.procedure.variables[@genitor_name]
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
      !@variant.nil? or parted?
    end

    # Return a ProductNatureVariant based on given informations
    def variant(intervention)
      if @variant =~ /\A\:/
        other = @variant[1..-1]
        return intervention.casts.find_by(variable: other).variant
      elsif Nomen::ProductNatureVariants[@variant]
        unless variant = ProductNatureVariant.find_by(nomen: @variant.to_s)
          variant = ProductNatureVariant.import_from_nomenclature(@variant)
        end
        return variant
      end
      return nil
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
