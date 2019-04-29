module Transitionable
  extend ActiveSupport::Concern

  included do
    transitionable
  end

  class Transition
    attr_reader :attribute, :resource

    class << self
      def from(*states)
        return @from || [] if states.empty?
        @from = states
      end

      def to(state = nil)
        return @to unless state.present?
        @to = state
      end

      def event(name = nil)
        return @event unless name.present?
        @event = name
      end
    end

    def initialize(resource, attribute: :state)
      @resource = resource
      @attribute = attribute
    end

    def can_run?
      from.include? resource.send(attribute)
    end

    def run
      return unless can_run?

      transition
    end

    protected

      def transition
        # Should be implemented in subclasses
      end
  end

  module ClassMethods
    def transitionable
      transitions_mod = self::Transitions
      transitions_mod.module_eval do
        Dir.glob(Rails.root.join('app', 'services', name.underscore, '*.rb'))
            .map { |path| [File.basename(path, '.rb').classify, path] }
            .each do |class_name, path|
          autoload class_name.to_sym, path
        end
      end

      transitions = transitions_mod.constants
                        .map { |cname| transitions_mod.const_get cname }
                        .select { |constant| constant < Transition }

      @transitionable_transitions = transitions.map { |transition| [transition.event, transition] }.to_h

      define_methods
    end

    def transitions
      @transitionable_transitions
    end

    private

      def define_methods
        define_method :_get_transition do |e|
          @transitionable_transitions[e]
        end

        transitions.keys.each do |event|
          define_method "can_#{event}?" do
            _get_transition(event)&.can_run?
          end

          define_method event do
            transition = _get_transition event

            transition.new(self).run if transition
          end
        end
      end
  end
end