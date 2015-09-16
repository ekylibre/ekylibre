((E, $) ->
  'use strict'

  $(document).on 'change', "*[data-sensor-vendor]", ->
    $el = $(@)
    $target = $($(@).data('sensor-target'))
    $url = $(@).data('sensor-url')

    if $el.val()?
      $.ajax
        url: $url
        data: {vendor_euid: $el.val()}
        success: (data, status, request) ->
          $target.html("")
          $.each data, (i, model) ->
            option = $("<option></option>")
            .val(model[1])
            .html(model[0])
            .appendTo($target)

          $target.prop('disabled', false)

          $target.trigger("change")
        error: () ->
          console.error "No model found"


  $(document).on 'change', "*[data-sensor-model]", ->
    $el = $(@)
    $parent = $($(@).data('sensor-parent'))
    $url = $(@).data('sensor-url')

    if $parent.val() and $el.val()
      $.ajax
        url: $url
        data: {vendor_euid: $parent.val(), model_euid: $el.val(), id: $el.data('sensor-id')}
        success: (data, status, request) ->
          true

  $(document).ready () ->
    $('*[data-sensor-vendor]').trigger('change')

) ekylibre, jQuery
