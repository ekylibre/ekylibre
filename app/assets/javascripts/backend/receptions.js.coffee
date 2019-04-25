((E, $) ->
  'use strict'

  $(document).ready ->
    $('input[data-warn-if-checked]').behave 'load', ->
      $('input[data-warn-if-checked]').each ->
        $input = $(this)

        messageText     = $input.data('warn-if-checked')
        messageSelector = $input.data('warn-in')
        $message        = $input.formScopedSelect(messageSelector)

        # Fallback if messageSelector doesn't match anything in scope
        $defaultMessage = $('<span class="warn-message"></span>')
        if $message.length is 0
          $input.formScope().append($defaultMessage)
          $message = $defaultMessage

        showOrHideMessage = (input) ->
          if $input.prop('checked')
            $message.show()
          else
            $message.hide()

        $message.html(messageText) if $message.is(':empty')

        showOrHideMessage($input) # Initial display
        $input.click showOrHideMessage # Update on input change


    $('h2[data-warn-if-checked]').behave 'load', ->
      $('h2[data-warn-if-checked]').each ->
        h2 = $(this)
        h2.html(h2.data('warn-if-checked'))
        if $('input[data-warn-if-checked]:checked').length >= 1
          h2.show()
        $('input[data-warn-if-checked]').click ->
          if $('input[data-warn-if-checked]:checked:visible').length >= 1
            h2.show()
          else
            h2.hide()

    $('table.list').on 'cocoon:after-insert', ->
      $('*[data-iceberg]').on "iceberg:inserted", ->
        that = $(this)
        $(this).find('*[data-association]').each (i, cocoonBtn) ->
          node = $(cocoonBtn).data('association-insertion-node')
          storageContainer = $(node).parent()
          storageContainer.on 'cocoon:after-insert cocoon:after-remove', ->
            E.toggleValidateButton(that)
            E.setStorageUnitName(that)

    $('.new_reception, .edit_reception').on 'change', '#reception_reconciliation_state', (event) ->
      checked = $(event.target).is(':checked')

      if checked
        $(event.target).val('accepted')
      else
        $(event.target).val('to_reconciliate')


) ekylibre, jQuery
