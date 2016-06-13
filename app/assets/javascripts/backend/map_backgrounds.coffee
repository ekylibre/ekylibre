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
        $(@).find('.map-background-by-default').toggleClass('hide')

        if data.new_default?
          $(@).find('.map-background-by-default.active').removeClass('active')
          $('.map-backgrounds-viewport').find("[data-id=#{data.new_default}]").find('.map-background-by-default').addClass('active')

    )

  $(document).on 'ajax:success', ".map-background-by-default", () ->
    $('.map-background-by-default.active').removeClass('active')
    $(@).toggleClass 'active'

  $(document).on 'ajax:success', ".map-background-delete a", () ->
    $(@).closest('.map-background-container').remove()


  return
) jQuery