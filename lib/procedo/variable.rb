module Procedo

  class Variable
    attr_reader :name, :procedure, :value, :abilities, :variety

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_sym
      @new = !element.attr("new").blank?
      @value = element.attr("value").to_s
      @abilities = element.attr("abilities").to_s
      @variety = element.attr("variety").to_s
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

  end

end
