module Calculus
  module ManureManagementPlan
    @registered_methods = {}.with_indifferent_access

    class << self
      def estimate_expected_yield(options = {})
        new_method(options).estimate_expected_yield
      end

      def compute(options = {})
        new_method(options).compute
      end

      def find_method(name)
        class_name = @registered_methods[name]
        raise "Cannot find method: #{name.inspect}" unless class_name
        class_name.constantize
      end

      def method_exist?(name)
        @registered_methods[name].present?
      end

      def new_method(options)
        find_method(options[:method]).new(options)
      end

      # Register a method for manure management plan
      def register_method(name, class_name)
        @registered_methods[name] = class_name
      end

      # Produces an array for select options
      def method_selection(options = {})
        @registered_methods.keys.collect do |n|
          [human_method_name(n, options), n.to_s]
        end.sort_by(&:first)
      end

      def human_method_name(name, options = {})
        "manure_management_method.#{name}".t({ default: ["labels.#{name}".to_sym, name.to_s.humanize] }.merge(options))
      end
    end
  end
end

require 'calculus/manure_management_plan/method'
require 'calculus/manure_management_plan/external'

Calculus::ManureManagementPlan.register_method :external, 'Calculus::ManureManagementPlan::External'
