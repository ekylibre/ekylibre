module Transitionable
  extend ActiveSupport::Concern

  included do
    transitionable
  end

  class TransitionError < StandardError
    attr_reader :original, :resource, :transition

    def initialize(msg, resource:, transition:, original: nil)
      super msg
      @original = original
      @resource = resource
      @transition = transition
    end

    def backtrace
      if original
        original.backtrace
      else
        super
      end
    end

    def interpolations
      {}
    end
  end

  class TransitionFailedError < TransitionError
    def initialize(resource:, transition:, original: nil)
      super "Error while running transition for #{resource}: #{original.message}", resource: resource, original: original, transition: transition
    end

  end

  class PreconditionFailedError < TransitionError
    def initialize(resource:, transition:)
      super "Cannot run transition for #{resource}: precondition test is false", resource: resource, transition: transition
    end
  end

  class TransitionAbortedError < TransitionError
    attr_accessor :reason

    def initialize(reason, resource:, transition:)
      super "Transition manually aborted: #{reason}", resource: resource, transition: transition
    end

    def interpolations
      { **super, reason: reason }
    end
  end

  class ExplainedTransitionError < TransitionError
    attr_reader :explanation, :options

    def initialize(explanation, options, transition:, resource:, original:)
      super generate_message(resource, transition, original, explanation), resource: resource, original: original, transition: transition

      @explanation = explanation
      @options = options
    end

    private

      def generate_message(resource, transition, original, explanation)
        "Error (#{explanation}) while running transition (#{transition.class.event}) for #{resource}: #{original.message}"
      end
  end

  class Transition
    attr_reader :attribute, :resource
    attr_accessor :error

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
      self.class.from.include? resource.send(attribute).to_sym
    end

    def run
      run!
      true
    rescue TransitionError => error
      @error = error
      false
    end

    def run!
      raise PreconditionFailedError.new(resource: resource, transition: self) unless can_run?

      res = catch :abort do
        transition
        :ok
      end

      raise TransitionAbortedError.new(res, resource: resource, transition: self) unless res == :ok
    rescue TransitionError
      raise
    rescue StandardError => error
      raise TransitionFailedError.new(resource: resource, original: error, transition: self)
    end

    protected

      def explain(explanation, **options)
        yield
      rescue StandardError => original
        raise ExplainedTransitionError.new(explanation, options, transition: self, resource: resource, original: original)
      end

      def transition
        raise NotImplementedError
      end
  end

  module ClassMethods
    def transitionable
      Dir.glob(Rails.root.join('app', 'services', self.name.underscore, 'transitions', '*.rb'))
        .map { |path| [File.basename(path, '.rb').classify, path] }
        .select { |(_, b)| File.exist? b }
        .each do |class_name, path|
        autoload class_name.to_sym, path
        require_dependency path
      end

      return unless self.constants.include? :Transitions

      transitions_mod = self::Transitions
      transitions = transitions_mod.constants
                      .map { |cname| transitions_mod.const_get cname }
                      .select { |constant| constant < Transition }

      @transitionable_transitions = transitions.map { |transition| [transition.event, transition] }.to_h

      define_transition_getter
      define_methods_for self.transitions
    end

    def transitions
      @transitionable_transitions || {}
    end

    private

      def define_transition_getter
        define_method :_get_transition do |e|
          self.class.transitions[e]
        end
      end

      def define_methods_for(transitions)
        transitions.keys.each do |event|
          define_method "can_#{event}?" do |**options|
            _get_transition(event).new(self, **options).can_run?
          end

          define_method event do |**options|
            transition = _get_transition event

            transition.new(self, **options).run if transition
          end
        end
      end
  end
end
