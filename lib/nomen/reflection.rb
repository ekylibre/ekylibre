module Nomen
  class Reflection
    attr_reader :active_record, :name, :class_name, :foreign_key, :scope, :options, :nomenclature, :klass

    def initialize(active_record, name, options = {})
      @options = options
      @name = name.to_s
      @active_record = active_record
      @class_name = options[:class_name] || name.to_s.classify
      @foreign_key = (options[:foreign_key] || name).to_s
      @scope = options[:scope]
      @nomenclature = class_name.underscore.pluralize
      @klass = Nomen.find(@nomenclature)
    end

    alias_method :model, :active_record

    def macro
      :belongs_to
    end

    # Returns true if self and other_aggregation have the same name attribute, active_record attribute, and other_aggregation has an options hash assigned to it.
    def ==(other_aggregation)
      other_aggregation.is_a?(self.class) &&
        name == other_aggregation.name &&
        !other_aggregation.options.nil? &&
        active_record == other_aggregation.active_record
    end

    def all(*args)
      @klass ? @klass.all(*args) : []
    end
  end
end
