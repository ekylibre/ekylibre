module Ekylibre
  module Access
    class Right
      attr_reader :interaction, :resource, :actions, :dependencies

      def initialize(resource, interaction, options = {})
        @resource     = resource.to_sym
        @interaction  = interaction.to_sym
        @actions      = []
        @dependencies = []
        @origin  = options[:origin] || :unknown
        options[:dependencies].each do |dependency|
          add_dependency(dependency)
        end if options[:dependencies]
        options[:actions].each do |action|
          add_action(action)
        end if options[:actions]
      end

      # Add an access right action
      def add_action(action)
        @actions << action unless @actions.include? action
      end

      # Add an access right dependency
      def add_dependency(right)
        @dependencies << right unless @dependencies.include?(right)
      end

      # Equality is based on name
      def ==(other)
        name == other.name
      end

      # Unique name of the right
      def name
        "#{@interaction}-#{@resource}"
      end

      def human_resource_name
        Ekylibre::Access.human_resource_name(@resource)
      end

      def human_interaction_name
        Ekylibre::Access.human_interaction_name(@interaction)
      end
    end
  end
end
