# frozen_string_literal: true

class StateBarBuilder
  attr_reader :attribute, :options, :resource

  def initialize(resource, attribute, options = {})
    @resource = resource
    @attribute = attribute
    @options = options
  end

  def build
    transitions = extract_possible_transitions_from resource

    buttons = states_from(resource)
                .map do |state|
      transition = transitions.fetch(state.to_sym, nil)
      StateBarHelper::Button.new(
        state,
        current: (state.to_sym == resource.send(attribute).to_sym),
        transition: transition,
        label: rename(state)
      )
    end

    StateBarHelper::StateBar.new(*buttons, transitions_enabled: transitions_enabled?)
  end

  private

    def rename(state)
      options.fetch(:renamings, nil)&.fetch(state.to_sym, nil)&.t scope: "models.#{resource.class.model_name.param_key}.states"
    end

    def transitions_enabled?
      !options.fetch(:disable_transitions, false)
    end

    def states_from(resource)
      return states_from_transitionable resource if defined?(Transitionable) && resource.class < Transitionable

      states_from_state_machine resource
    end

    def states_from_transitionable(resource)
      resource.class.send(attribute).values
    end

    def states_from_state_machine(resource)
      values = resource.class.state_machine.states
      values.each do |state|
        def state.to_sym
          name
        end
      end

      values
    end

    def extract_possible_transitions_from(resource)
      return extract_possible_transitions_from_transitionable resource if defined?(Transitionable) && resource.class < Transitionable

      extract_possible_transitions_from_state_machine resource
    end

    def extract_possible_transitions_from_transitionable(resource)
      transitions_mod = resource.class.const_get :Transitions
      transitions_mod.constants
        .map { |c| transitions_mod.const_get c }
        .select { |c| c < Transitionable::Transition }
        .select { |t| t.from.include? resource.send(attribute).to_sym }
        .map { |t| [t.to, t] }
        .to_h
    end

    def extract_possible_transitions_from_state_machine(resource)
      resource.state_transitions
        .map { |t| [t.to.to_sym, t] }
        .to_h
    end
end
