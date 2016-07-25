((E, $) ->
  'use strict'

  $(document).on "change keyup", "#plant_density_abacus_seeding_density_unit,.counting-seeding-density", (event)->
    element = $(this)
    label = element.find('option:selected').html()
    element.closest('.counting').find('.seeding-density-unit').html(label)

  $(document).on "change keyup", "#plant_density_abacus_sampling_length_unit,.counting-sampling-length", (event)->
    element = $(this)
    label = element.find('option:selected').html()
    element.closest('.counting').find('.sampling-length-unit').html(label)


) ekylibre, jQuery
