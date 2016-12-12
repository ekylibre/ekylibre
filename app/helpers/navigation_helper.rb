# Helper to add record-to-record navigation.
module NavigationHelper
  # Used when missing a scope.
  class MissingScopeError < NoMethodError
    def initialize(scope, resource, backtrace, *args)
      error_message = "Scope `#{scope}` unknown in resource #{resource}."
      super(error_message, backtrace, *args)
    end
  end

  # Used when trying to order with non-existent table columns.
  class OrderingCriterionNotFound < ActiveRecord::StatementInvalid
    def initialize(pg_error, *args)
      column = pg_error.message.split('"').second
      error_message = "Column #{column} is specified in order but isn't present in table columns."
      super(error_message, pg_error.backtrace, *args)
    end
  end

  def navigation(resource, order: { id: :asc }, naming_method: :name, scope: nil)
    order = { order.to_sym => :asc } unless order.respond_to?(:keys)
    nexts = next_records(resource, order, scope)

    content_for :heading_toolbar do
      render 'backend/shared/record_navigation',
             previous: named(nexts[:down], naming_method),
             following: named(nexts[:up], naming_method)
    end
  end

  private

  def named(collection, naming_method)
    {
      record: collection.first,
      name:   name_for(collection.first, naming_method)
    }
  rescue ActiveRecord::StatementInvalid => e
    raise e unless (pg_error = e.original_exception).is_a?(PG::UndefinedColumn)
    raise OrderingCriterionNotFound, pg_error
  end

  def next_records(resource, order, scope)
    matching_attrs = resource.attributes.slice(*order.keys.map(&:to_s))
    other_records  = navigable(resource.class, order, scope, resource.id).order(**order)
    reversed = (order.first.last =~ /desc/)

    lists = %i(down up).map do |dir|
      [dir, matching_attrs.reduce(other_records, &get_next_record_method(going: dir, reverse: reversed))]
    end.to_h
    lists[:down] = lists[:down].reverse_order
    lists
  end

  def name_for(record, method)
    return nil unless method.present?
    Maybe(record).send(method.to_sym).or_nil
  end

  def navigable(items, order, scope, excluded)
    scoped   = scope
    scoped &&= items.send(scope)
    scoped ||= items
    scoped.where.not(id: excluded).order(**order)
  rescue NoMethodError => e
    raise MissingScopeError.new(e.name, e.missing_name, e.backtrace, *e.args)
  end

  def get_next_record_method(going: :up, reverse: false)
    operator = case going
               when /up/   then reverse ? '<=' : '>='
               when /down/ then reverse ? '>=' : '<='
               end
    lambda do |resources, condition|
      key, value = *condition
      resources.where("#{key} #{operator} #{value.inspect.tr('"', "'")}")
    end
  end
end
