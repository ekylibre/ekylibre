# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

(($) ->
  "use strict"
  $(document).on 'click', '[data-enable-url]', () ->
    $.ajax(
      url: $(@).data('enable-url')
      method: 'PUT'
      dataType: 'json'
      success: () =>
        $(@).toggleClass 'active'

    )

  $(document).on 'ajax:success', ".map-background-by-default", () ->
    console.log @
    $('.map-background-by-default.active').removeClass('active')
    $(@).toggleClass 'active'


  return
) jQuery