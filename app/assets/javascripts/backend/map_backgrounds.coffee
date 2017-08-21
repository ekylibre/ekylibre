# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

(($) ->
  "use strict"
  $(document).on 'click', '[data-enable-url]', () ->
    $.ajax(
      url: $(@).data('enable-url')
      method: 'POST'
      dataType: 'json'
      success: (data) =>
        $(@).toggleClass 'active'
        $(@).find('.map-layer-by-default').toggleClass('hide')

        if data.new_default?
          $(@).find('.map-layer-by-default.active').removeClass('active')
          $('.map-layers-viewport').find("[data-id=#{data.new_default}]").find('.map-layer-by-default').addClass('active')

    )

  $(document).on 'ajax:success', ".map-layer-by-default", () ->
    $('.map-layer-by-default.active').removeClass('active')
    $(@).toggleClass 'active'

  $(document).on 'ajax:success', ".map-layer-delete a", () ->
    $(@).closest('.map-layer-container').remove()


  return
) jQuery