module Unrollable
  # Methods that allow us to fetch various parameters from the input data.
  module Extracting
    extend Toolbelt

    AVAILABLE_OPTIONS = %i(model max order partial fill_in scope).freeze
    DEFAULT_OPTIONS = { max: 80, scope: :unscoped, visible_items_count: 10 }.freeze

    def self.options_from(arguments, defaults: true)
      if arguments.last.is_a?(Hash)
        options, arguments[-1] = arguments.last.partition { |k, _| AVAILABLE_OPTIONS.include?(k) }.map(&:to_h)
      end
      options ||= {}

      defaults ? DEFAULT_OPTIONS.merge(options) : options
    end

    def self.parameters_from(parameter)
      params = parameter.strip.split(/\s*\,\s*/) if parameter.is_a? String
      symbolized(params || parameter)
    end

    def self.scopes_from(params)
      return {} unless params[:scope]
      scope_is_without_params = params[:scope].is_a?(String) || params[:scope].is_a?(Symbol)
      return { params[:scope] => true } if scope_is_without_params
      params[:scope]
    end

    def self.fill_in_from(options, filters)
      return nil if (fill_in = options[:fill_in]) && options.key?(:fill_in)

      fill_in ||= filters.select(&:root?).map(&:name).first
      fill_in &&= fill_in.to_sym

      fill_present = fill_in.blank? || filters.map(&:name).include?(fill_in)

      fill_present ? fill_in : raise(<<-NO_FILL_IN)
        Fill-in column #{fill_in.inspect} not in filters #{filters.map(&:name)}.
      NO_FILL_IN
    end
  end
end
