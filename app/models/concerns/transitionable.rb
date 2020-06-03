##
# = Transitionable component
#
# The transitionable component aims to repoace the use of the
# state_machine gem.
#
# It provides a more explicit way of declaring states and transitions and
# the way to transition from one state from an other. It also allow a fine
# grain control of error management for each step of the transition.
#
# == Architecture
#
# The Transitionable concern to be included in each model that has a state
# and needs to declare transitions between these states.
#
# Each Transition for a given model should inherit of the Transition class.
# Transition classes should be put in the `services/<model>/transitions` folder
#
module Transitionable
  extend ActiveSupport::Concern

  included do
    transitionable
  end

  ##
  # Superclass for all Errorw thrown in a Transition
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

  ##
  # Basic error raised when no additional data is provided
  class TransitionFailedError < TransitionError
    def initialize(resource:, transition:, original: nil)
      super "Error while running transition for #{resource}: #{original.message}", resource: resource, original: original, transition: transition
    end

  end

  ##
  # Error raised when a transition is attempted and the can_run? method return false
  class PreconditionFailedError < TransitionError
    def initialize(resource:, transition:)
      super "Cannot run transition for #{resource}: precondition test is false", resource: resource, transition: transition
    end
  end

  ##
  # Raised when `throw :abort, <reason>` is called in the `transition` method
  class TransitionAbortedError < TransitionError
    attr_accessor :reason

    def initialize(reason, resource:, transition:)
      super "Transition manually aborted: #{reason}", resource: resource, transition: transition
    end

    def interpolations
      { **super, reason: reason }
    end
  end

  ##
  # Error that explains its cause. Raised when an error is raised in an `explain-ed block`
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


  ##
  # This is the base class that must be extended by all transitions.
  #
  # == Error handling
  #
  # To provide more information to tue user or programmes in case of a failure during the transition, instructions can be wrapped in an `explain` block.
  # Locales should be put in the transition.yml file.
  #
  class Transition
    attr_reader :attribute, :error, :resource

    class << self
      ##
      # DSL to define (or get when no argument is provided) the states from which the transition can be executed.
      # states should be Symbols. When there are more than one, just separate them by a comma.
      def from(*states)
        return @from || [] if states.empty?
        @from = states
      end

      ##
      # DSL to define (or get when no argument is provided) the destination state of the transition. Should be a Symbol.
      def to(state = nil)
        return @to unless state.present?
        @to = state
      end

      ##
      # DSL to define (or get when no argument is provided) the name of the event that the Transition represents
      def event(name = nil)
        return @event unless name.present?
        @event = name
      end
    end

    def initialize(resource, attribute: :state)
      @resource = resource
      @attribute = attribute
    end

    ##
    # Returns true if the Transition can be executed on the resource given a initialization.
    # The base implementation returns true if the resource is in a supported state.
    # *Can* and *should* be extended by subclasses
    def can_run?
      self.class.from.include? resource.send(attribute).to_sym
    end

    ##
    # Run the Transition. Returns true on success, false otherwise.
    # If an error occur, it can be accessed with the `error` property
    def run
      run!
      true
    rescue TransitionError => error
      @error = error
      false
    end

    ##
    # Run the Transition. Throw an exception in case of failure.
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

      ##
      # DSL allowing to attach to a given block some information that possibly explain the problem if an error is raised.
      # Given options are passed to the I18n helper and error messages are namespaced based on the class of the resource and the Transition event name
      def explain(explanation, **options)
        yield
      rescue StandardError => original
        raise ExplainedTransitionError.new(explanation, options, transition: self, resource: resource, original: original)
      end

      ##
      # This method has to be redefined in subclasses and should contain the transition logic, usually wrapped in a transaction.
      # The method is called only if the call to can_run? returns true
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
