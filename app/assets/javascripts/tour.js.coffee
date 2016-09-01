#= require tether
#= require shepherd

((E, $) ->
  "use strict";

  $(document).ready ->
    $("body[data-tour]").each ->
      element = $(this)
      options = element.data('tour')
      defaults = options.defaults
      for k, v of defaults.buttons
        if v.action is 'next'
          v.action = ->
            Shepherd.activeTour.next()
      tour = new Shepherd.Tour
        defaults: defaults
      for step in options.steps
        for k, v of step.buttons
          if v.action is 'next'
            v.action = ->
              Shepherd.activeTour.next()
        tour.addStep(step.id, step)
      tour.on 'complete', ->
        $.ajax
          url: options.url
          method: 'POST'
      tour.on 'cancel', ->
        $.ajax
          url: options.url
          method: 'POST'
      tour.start()
    true


) ekylibre, jQuery
