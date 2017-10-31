module Backend
  module ReceptionsHelper
    def reconciliation_state(reception)
      case reception.reconciliation_state
      when 'to_reconcile'
        html_class = 'no-reconciliate-title'
        text = :to_reconciliate.tl
      when 'reconcile'
        html_class = 'reconcile-title'
        text = :reconcile.tl
      end
      content_tag(:h2, text, class: "reconciliation-title #{html_class}")
    end
  end
end
