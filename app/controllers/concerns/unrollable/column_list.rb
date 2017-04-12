module Unrollable
  # Class representing a list of columns providing methods to convert them.
  class ColumnList
    include Toolbelt

    DEFAULT_COLUMNS = %i[title label full_name name code number reference_number].freeze

    def initialize(list, model)
      @model = model
      columns = deep_compact(list)

      available_methods = @model.column_names.map(&:to_sym)
      fallback = DEFAULT_COLUMNS & available_methods

      no_cols = "No column available to unroll #{@model.name} records."
      @columns = if_there(columns) || if_there(fallback)
      @columns || raise(no_cols)
    end

    def to_filters(object: nil, model: nil, parents: [])
      object ||= @columns
      model  ||= @model

      case object
      when Array then object.map { |o| to_filters(object: o, model: model, parents: parents) }
                            .flatten
      when Hash  then
        a = object.symbolize_keys.map do |k, v|
          to_filters(
            object: v,
            model: reflection_class(k, model),
            parents: parents + [k]
          )
        end
        a.flatten
      when Symbol, String then Filter.new(object, model, parents)
      else raise "Don't know how to handle object: #{object.inspect}."
      end
    end

    def to_includes(object: nil)
      object ||= @columns

      case object
      when Array then first_if_alone(object.map { |o| to_includes(object: o) }.compact)
      when Hash
        object.map do |k, v|
          a = [k, to_includes(object: v)]
          a.last.nil? ? k : [a].to_h
        end
      when Symbol, String then nil
      else raise "Don't know how to handle object: #{object.inspect}."
      end
    end

    protected

    def reflection_class(name, model)
      reflection = model.reflect_on_association(name)
      raise "Cannot find a reflection #{name} for #{model.name}" unless reflection

      reflection.class_name.constantize
    end
  end
end
