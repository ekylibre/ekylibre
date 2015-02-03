(($) ->
  'use strict'

  $(document).on 'click change', '*[data-toggle-timesteps]', ->
    element = $(this)
    if element.hasClass("active")
      $(".timestep.#{element.data('toggleTimesteps')}").addClass("hidden")
      element.removeClass("active")
    else
      $(".timestep.#{element.data('toggleTimesteps')}").removeClass("hidden")
      element.addClass("active")
    false

) jQuery
