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

    # Every model with a state bar now uses the Transitionable concern; the
    # state_machine branch this method used to carry is gone with the gem.
    def states_from(resource)
      resource.class.send(attribute).values
    end

    # Uses `to_for` rather than `to`: a transition may land on a different
    # state depending on where it starts from (Delivery#cancel, Shipment#cancel).
    def extract_possible_transitions_from(resource)
      current = resource.send(attribute).to_sym
      transitions_mod = resource.class.const_get :Transitions
      transitions_mod.constants
        .map { |c| transitions_mod.const_get c }
        .select { |c| c < Transitionable::Transition }
        .select { |t| t.from.include? current }
        .map { |t| [t.to_for(current), t] }
        .reject { |(destination, _)| destination.nil? }
        .to_h
    end
end
