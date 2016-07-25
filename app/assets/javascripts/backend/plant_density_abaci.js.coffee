((E, $) ->
  'use strict'

  $(document).on "change keyup", ".activity_plant_density_abaci_seeding_density_unit select", (event)->
    element = $(this)
    label = element.find('option:selected').html()
    element.closest('.plant-density-abacus').find('.seeding-density-unit').html(label)

  $(document).on "change keyup", ".activity_plant_density_abaci_sampling_length_unit select", (event)->
    element = $(this)
    label = element.find('option:selected').html()
    element.closest('.plant-density-abacus').find('.sampling-length-unit').html(label)

  $(document).on "cocoon:after-insert", ".plant-density-abacus #items-field", (event)->
    element = $(this)
    element.closest('.plant-density-abacus').find('select').trigger('change')

) ekylibre, jQuery
