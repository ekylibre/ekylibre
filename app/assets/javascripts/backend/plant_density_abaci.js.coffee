((E, $) ->
  'use strict'

  $(document).on "change keyup", "#plant_density_abacus_seeding_density_unit", (event)->
    element = $(this)
    label = element.find('option:selected').html()
    element.closest('form').find('.seeding-density-unit').html(label)

  $(document).on "change keyup", "#plant_density_abacus_sampling_length_unit", (event)->
    element = $(this)
    label = element.find('option:selected').html()
    element.closest('form').find('.sampling-length-unit').html(label)


) ekylibre, jQuery
