module StateBadgeSetHelper
  # @param [Synbol] state current state
  # @param [Hash] html html options
  # @param [Array<Symbol>] states list of possible states in [accepted, allowed,
  #   closed, confirmed, draft, forbidden, incident, reconcile, to_reconcile]
  #   see app/assets/stylesheets/themes/tekyla/components/state-badge-set.scss
  def state_badge_set(state, html: {}, states: {})
    if states.is_a? Array
      states = states.map { |e| [e, e] }.to_h
    end

    set_style = state.present? ? "state-badge-set--#{state.to_s.dasherize}" : ""

    content_tag :div, **html.except(:classes), class: [*html.fetch(:classes, []), 'state-badge-set', set_style] do
      states.map do |id, name|
        state_badge name.tl, class: ['state-badge-set__badge', "state-badge-set__badge--#{id.to_s.dasherize}"]
      end.reduce(&:+)
    end
  end

  private

    def state_badge(content, **html_options)
      content_tag :h2, content, **html_options
    end
end
