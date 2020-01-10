module StateBarHelper
  COLORS = {
    intermediate: %i[draft],
    rejected: %i[aborted lost refused scrapped sold],
    validated: %i[done finished given in_use invoice ongoing order repaid won]
  }.reverse

  def self.color_for(state, default = :intermediate)
    COLORS[state.to_sym] || default
  end

  class StateBar
    attr_reader :buttons

    # Creates a StateBar with the provided buttons.
    # If `transitions_enabled` is false, buttons should not be rendered as clickable
    def initialize(*buttons, transitions_enabled: true)
      @buttons = buttons
      @transitions_enabled = transitions_enabled
    end

    def transitions_enabled?
      @transitions_enabled
    end
  end

  class Button
    attr_reader :name

    # Creates a Button
    # If `label` is provided, it will replace the default value (+human_name+ of the +name+ parameter)
    def initialize(name, transition:, current: false, label: nil)
      @name = name
      @transition = transition
      @current = current
      @label = label
    end

    def current?
      @current
    end

    def enabled?
      @transition.present?
    end

    def label
      @label || name.human_name
    end

    def event
      @transition.event if @transition
    end

    def title
      event&.ta
    end

    def styles
      additional = [type_style, state_style].compact.map { |s| "state-bar__state--#{s}" }
      ['state-bar__state', *additional]
    end

    def state_style
      return :current if current?
      return :disabled unless enabled?
      nil
    end

    def type_style
      StateBarHelper.color_for name
    end
  end

  def state_bar(resource, options = {})
    sb = StateBarBuilder.new(resource, :state, options).build

    render 'helpers/state-bar/state_bar', resource: resource, state_bar: sb
  end

  def main_state_bar(resource, options = {}, &block)
    content_for(:main_statebar, state_bar(resource, options, &block))
  end

  def main_state_bar_tag
    content_for(:main_statebar) if content_for?(:main_statebar)
  end

end