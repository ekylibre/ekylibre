# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

(($) ->
  "use strict"
  $(document).on 'ajax:success', ".map-background-display", () ->
    $(@).toggleClass 'enable'

  return
) jQuery