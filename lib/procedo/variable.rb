module Procedo

  class Variable
    attr_reader :name, :procedure, :value, :abilities, :variety, :derivative_of

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_sym
      @new = !element.attr("new").blank?
      @value = element.attr("value").to_s
      @abilities = element.attr("abilities").to_s.strip.split(/\s*\,\s*/)
      @variety = element.attr("variety").to_s if element.has_attribute?("variety")
      @variety = @variety.to_sym if @variety.is_a?(String) and @variety !=~ /\:/
      @derivative_of = element.attr("derivative-of").to_s if element.has_attribute?("derivative-of")
      @derivative_of = @derivative_of.to_sym if @derivative_of.is_a?(String) and @derivative_of !=~ /\:/
      @roles = element.attr("roles").to_s.strip.split(/\s*\,\s*/)
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

    # Returns scope hash for unroll
    def scope_hash
      hash = {}
      hash[:can] = abilities.join(',') unless abilities.empty?
      hash[:of_variety] = variety if variety.is_a?(Symbol)
      hash[:derivative_of] = derivative_of if derivative_of.is_a?(Symbol)
      return hash
    end

  end

end
