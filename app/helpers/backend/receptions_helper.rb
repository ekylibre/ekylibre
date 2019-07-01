module Backend
  module ReceptionsHelper
    def reception_incident_badge(reception)
      content_tag :h2, :reception_incident.tl, class: [(:hidden unless reception.items.any? &:non_compliant)]
    end

    def reconciliation_state(reception, print_both: false)
      elements = ''.html_safe
      if print_both || reception.reconciliation_state == 'to_reconcile'
        html_class = 'no-reconciliate-title'
        text = :to_reconciliate.tl
        elements << content_tag(:h2, text, class: ['reconciliation-title', html_class, (:hidden if reception.reconciliation_state == 'reconcile')])
      end

      if print_both || reception.reconciliation_state == 'reconcile'
        html_class = 'reconcile-title'
        text = :reconcile.tl
        elements << content_tag(:h2, text, class: ['reconciliation-title', html_class, (:hidden if reception.reconciliation_state == 'to_reconcile')])
      end

      elements
    end
  end
end
