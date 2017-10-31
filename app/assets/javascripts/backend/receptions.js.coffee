((E, $) ->
  'use strict'

  $(document).ready ->
    $('input[data-warn-if-checked]').behave 'load', ->
      $('input[data-warn-if-checked]').each ->
        input = $(this)
        container = input.closest('.non-compliant')
        if container.find('.warn-message').length is 0
          container.prepend($('<span class="warn-message"></span>').html(input.data('warn-if-checked')).hide())
        if input.prop('checked')
          container.find('.warn-message').show()
        input.click ->
          if input.prop('checked')
            container.find('.warn-message').show()
          else
            container.find('.warn-message').hide()

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
