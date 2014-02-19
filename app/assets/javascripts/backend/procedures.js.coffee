# Generated with `rake procedures:precompile`.
# Changes won't be kept after next compilation.

(($) ->
  'use strict'
  $.procedures = 
    base:
      allInOneSowing:
        v00:
          seedsToSow:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population * 3)
                true
          fertilizerToSpread:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="fertilizer_to_spread_population"]').val(population * 3)
                true
          insecticideToInput:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="insecticide_to_input_population"]').val(population * 3)
                true
          moluscicideToInput:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="moluscicide_to_input_population"]').val(population * 3)
                true
      animalTreatment:
        v00:
          medicineToGive:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="medicine_to_give_population"]').val(population * 3)
                true
      directSilage:
        v00:
          silage:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="silage_population"]').val(population * 3)
                true
      grainsHarvest:
        v00:
          grains:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="grains_population"]').val(population * 3)
                true
          straws:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="straws_population"]').val(population * 3)
                true
      indirectSilage:
        v00:
          silage:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="silage_population"]').val(population * 3)
                true
      mammalHerdMilking:
        v00:
          milk:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="milk_population"]').val(population * 3)
                true
      mammalMilking:
        v00:
          milk:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="milk_population"]').val(population * 3)
                true
      manualVineHarvest:
        v00:
          fruits:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="fruits_population"]').val(population * 3)
                true
      mecanicalVineHarvest:
        v00:
          fruits:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="fruits_population"]').val(population * 3)
                true
      mineralFertilizing:
        v00:
          fertilizerToSpread:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="fertilizer_to_spread_population"]').val(population * 3)
                true
      organicFertilizing:
        v00:
          manureToSpread:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="manure_to_spread_population"]').val(population * 3)
                true
      partialSprayingOnCultivation:
        v00:
          medicineToSpray:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="medicine_to_spray_population"]').val(population * 3)
                true
          cultivationToTarget:
            shape:
              updateOtherHandlers: (input) ->
                shape = parseFloat(input.val())
                $('input[data-variable-destination="cultivation_to_target_shape"]').val(shape * 3)
                true
      plantGrinding:
        v00:
          grinded:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="grinded_population"]').val(population * 3)
                true
      plantMowing:
        v00:
          straw:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="straw_population"]').val(population * 3)
                true
      sowing:
        v00:
          seedsToSow:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * 2)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val(population * 4)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val(population * 2)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val(population * 5)
                true
            netMassKilogram:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population * 1)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val(population * 4)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val(population * 2)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val(population * 5)
                true
            massAreaDensityKilogramPerHectare:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population * 1)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * 4)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val(population * 2)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val(population * 5)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val(population * 5)
                true
            grainsAreaDensityUnityPerSquareMeter:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * 5)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val(population * 5)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val(population * 1)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val(population * 4)
                true
            grainsAreaDensityThousandPerHectare:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population * 5)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * 1)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val(population * 5)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val(population * 1)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val(population * 5)
                true
            grainsCountThousand:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population * 5)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * 5)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val(population * 4)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val(population * 3)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val(population * 4)
                true
      sprayingOnCultivation:
        v00:
          medicineToSpray:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="medicine_to_spray_population"]').val(population * 3)
                true
      strawBunching:
        v00:
          strawBales:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="straw_bales_population"]').val(population * 3)
                true
      vinePlant:
        v00:
          plantsToFix:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="plants_to_fix_population"]').val(population * 3)
                true
      wineTransfer:
        v00:
          wineToMove:
            population:
              updateOtherHandlers: (input) ->
                population = parseFloat(input.val())
                $('input[data-variable-destination="wine_to_move_population"]').val(population * 3)
                true
  # Adds events on inputs
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-seeds_to_sow-population"]', -> $.procedures.base.allInOneSowing.v00.seedsToSow.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-fertilizer_to_spread-population"]', -> $.procedures.base.allInOneSowing.v00.fertilizerToSpread.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-insecticide_to_input-population"]', -> $.procedures.base.allInOneSowing.v00.insecticideToInput.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-moluscicide_to_input-population"]', -> $.procedures.base.allInOneSowing.v00.moluscicideToInput.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-animal_treatment-v0_0-medicine_to_give-population"]', -> $.procedures.base.animalTreatment.v00.medicineToGive.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-direct_silage-v0_0-silage-population"]', -> $.procedures.base.directSilage.v00.silage.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-grains_harvest-v0_0-grains-population"]', -> $.procedures.base.grainsHarvest.v00.grains.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-grains_harvest-v0_0-straws-population"]', -> $.procedures.base.grainsHarvest.v00.straws.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-indirect_silage-v0_0-silage-population"]', -> $.procedures.base.indirectSilage.v00.silage.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mammal_herd_milking-v0_0-milk-population"]', -> $.procedures.base.mammalHerdMilking.v00.milk.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mammal_milking-v0_0-milk-population"]', -> $.procedures.base.mammalMilking.v00.milk.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-manual_vine_harvest-v0_0-fruits-population"]', -> $.procedures.base.manualVineHarvest.v00.fruits.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mecanical_vine_harvest-v0_0-fruits-population"]', -> $.procedures.base.mecanicalVineHarvest.v00.fruits.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mineral_fertilizing-v0_0-fertilizer_to_spread-population"]', -> $.procedures.base.mineralFertilizing.v00.fertilizerToSpread.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-organic_fertilizing-v0_0-manure_to_spread-population"]', -> $.procedures.base.organicFertilizing.v00.manureToSpread.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-partial_spraying_on_cultivation-v0_0-medicine_to_spray-population"]', -> $.procedures.base.partialSprayingOnCultivation.v00.medicineToSpray.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-partial_spraying_on_cultivation-v0_0-cultivation_to_target-shape"]', -> $.procedures.base.partialSprayingOnCultivation.v00.cultivationToTarget.shape.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-plant_grinding-v0_0-grinded-population"]', -> $.procedures.base.plantGrinding.v00.grinded.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-plant_mowing-v0_0-straw-population"]', -> $.procedures.base.plantMowing.v00.straw.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]', -> $.procedures.base.sowing.v00.seedsToSow.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]', -> $.procedures.base.sowing.v00.seedsToSow.netMassKilogram.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]', -> $.procedures.base.sowing.v00.seedsToSow.massAreaDensityKilogramPerHectare.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]', -> $.procedures.base.sowing.v00.seedsToSow.grainsAreaDensityUnityPerSquareMeter.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]', -> $.procedures.base.sowing.v00.seedsToSow.grainsAreaDensityThousandPerHectare.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]', -> $.procedures.base.sowing.v00.seedsToSow.grainsCountThousand.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-spraying_on_cultivation-v0_0-medicine_to_spray-population"]', -> $.procedures.base.sprayingOnCultivation.v00.medicineToSpray.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-straw_bunching-v0_0-straw_bales-population"]', -> $.procedures.base.strawBunching.v00.strawBales.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-vine_plant-v0_0-plants_to_fix-population"]', -> $.procedures.base.vinePlant.v00.plantsToFix.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-wine_transfer-v0_0-wine_to_move-population"]', -> $.procedures.base.wineTransfer.v00.wineToMove.population.updateOtherHandlers($(this))

  true
) jQuery
