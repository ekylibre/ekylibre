module Transitionable
  extend ActiveSupport::Concern

  included do
    transitionable
  end

  class TransitionError < StandardError
    attr_reader :resource, :original

    def initialize(msg, resource, original = nil)
      super msg
      @resource = resource
      @original = original
    end

    def backtrace
      if original
        original.backtrace
      else
        super
      end
    end
  end

  class TransitionFailedError < TransitionError
    def initialize(resource, original)
      super "Error while running transition for #{resource}: #{original.message}", resource, original
    end
  end

  class PreconditionFailedError < TransitionError
    def initialize(resource)
      super "Cannot run transition for #{resource}: precondition test is false", resource
    end
  end

  class TransitionAbortedError < TransitionError
    def initialize(resource)
      super "Transition manually aborted", resource
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
      raise PreconditionFailedError.new(resource)  unless can_run?

      res = catch :abort do
        transition
        :ok
      end

      raise TransitionAbortedError.new(resource) unless res == :ok
    rescue TransitionError
      raise
    rescue StandardError => error
      raise TransitionFailedError.new(resource, error)
    end

    protected

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
