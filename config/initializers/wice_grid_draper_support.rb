if defined?(Wice::WiceGrid) && defined?(Draper::CollectionDecorator) && defined?(Draper::Decorator)

  module WiceGridDraperSupport
    def initialize(klass_or_relation, controller, opts = {})
      @decorate = opts.delete(:decorate)
      super
    end

    def read
      super
      @resultset = @resultset.decorate(klass: @klass) if @decorate == true
    end
  end

  module DraperCollectionWiceGridSupport
    active_record_methods = %i[
      columns
      connection
      merge_conditions
      page
      table_name
      unscoped
      where
    ]
    delegate *active_record_methods, to: :klass

    active_record_relation_methods = %i[
      current_page
      last_page?
      limit_value
      num_pages
      offset_value
      total_count
      total_pages
    ]

    delegate *active_record_relation_methods, to: :object

    attr_reader :klass

    def initialize(object, options = {})
      @klass = options.delete(:klass)
      super
    end

    def is_a?(klass)
      klass == ActiveRecord::Relation || super
    end
  end

  class Wice::WiceGrid
    prepend WiceGridDraperSupport
  end

  class Draper::CollectionDecorator
    prepend DraperCollectionWiceGridSupport
  end

  class Draper::Decorator
    def self.decorate_collection(object, options = {})
      options.assert_valid_keys(:with, :context, :klass)
      collection_decorator_class.new(object, options.reverse_merge(with: self))
    end
  end
end
