((E, $) ->
  'use strict'

  $(document).on 'click', '.fec-compliance .fec-icon-error', (e) ->
    entryId = $(e.target).parents('tr').data('entryId')
    category = $(e.target).data('category')
    $.get
      url: 'draft_journal/fec_compliance_errors',
      data: { entry_id: entryId, category: category }
      success: (data) ->
        modal = new ekylibre.modal('#fec-compliance-errors')
        modal.removeModalContent()
        modal.getModalContent().append(data)
        modal.getModal().modal('show')

  return
) ekylibre, jQuery
