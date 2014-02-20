# Generated with `rake procedures:precompile`.
# Changes won't be kept after next compilation.

(($) ->
  'use strict'
  $.handlers =
    base:
      allInOneSowing:
        v00:
          seedsToSow:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-all_in_one_sowing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('seeds_to_sow')
                # Computations
                population = __value__
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population)
                true
          fertilizerToSpread:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-all_in_one_sowing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('fertilizer_to_spread')
                # Computations
                population = __value__
                $('input[data-variable-destination="fertilizer_to_spread_population"]').val(population)
                true
          insecticideToInput:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-all_in_one_sowing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('insecticide_to_input')
                # Computations
                population = __value__
                $('input[data-variable-destination="insecticide_to_input_population"]').val(population)
                true
          moluscicideToInput:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-all_in_one_sowing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('moluscicide_to_input')
                # Computations
                population = __value__
                $('input[data-variable-destination="moluscicide_to_input_population"]').val(population)
                true
      animalTreatment:
        v00:
          medicineToGive:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-animal_treatment-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('medicine_to_give')
                # Computations
                population = __value__
                $('input[data-variable-destination="medicine_to_give_population"]').val(population)
                true
      directSilage:
        v00:
          silage:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-direct_silage-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('silage')
                # Computations
                population = __value__
                $('input[data-variable-destination="silage_population"]').val(population)
                true
      grainsHarvest:
        v00:
          grains:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-grains_harvest-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('grains')
                # Computations
                population = __value__
                $('input[data-variable-destination="grains_population"]').val(population)
                true
          straws:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-grains_harvest-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('straws')
                # Computations
                population = __value__
                $('input[data-variable-destination="straws_population"]').val(population)
                true
      indirectSilage:
        v00:
          silage:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-indirect_silage-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('silage')
                # Computations
                population = __value__
                $('input[data-variable-destination="silage_population"]').val(population)
                true
      mammalHerdMilking:
        v00:
          milk:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-mammal_herd_milking-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('milk')
                # Computations
                population = __value__
                $('input[data-variable-destination="milk_population"]').val(population)
                true
      mammalMilking:
        v00:
          milk:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-mammal_milking-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('milk')
                # Computations
                population = __value__
                $('input[data-variable-destination="milk_population"]').val(population)
                true
      manualVineHarvest:
        v00:
          fruits:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-manual_vine_harvest-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('fruits')
                # Computations
                population = __value__
                $('input[data-variable-destination="fruits_population"]').val(population)
                true
      mecanicalVineHarvest:
        v00:
          fruits:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-mecanical_vine_harvest-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('fruits')
                # Computations
                population = __value__
                $('input[data-variable-destination="fruits_population"]').val(population)
                true
      mineralFertilizing:
        v00:
          fertilizerToSpread:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-mineral_fertilizing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('fertilizer_to_spread')
                # Computations
                population = __value__
                $('input[data-variable-destination="fertilizer_to_spread_population"]').val(population)
                true
      organicFertilizing:
        v00:
          manureToSpread:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-organic_fertilizing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('manure_to_spread')
                # Computations
                population = __value__
                $('input[data-variable-destination="manure_to_spread_population"]').val(population)
                true
      partialSprayingOnCultivation:
        v00:
          medicineToSpray:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-partial_spraying_on_cultivation-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('medicine_to_spray')
                # Computations
                population = __value__
                $('input[data-variable-destination="medicine_to_spray_population"]').val(population)
                true
          cultivationToTarget:
            shape:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-partial_spraying_on_cultivation-0.0')
                __value__ = parseFloat input.val() # :geometry
                self = __procedure__.actor('cultivation_to_target')
                # Computations
                shape = __value__
                $('input[data-variable-destination="cultivation_to_target_shape"]').val(shape)
                true
      plantGrinding:
        v00:
          grinded:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-plant_grinding-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('grinded')
                # Computations
                population = __value__
                $('input[data-variable-destination="grinded_population"]').val(population)
                true
      plantMowing:
        v00:
          straw:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-plant_mowing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('straw')
                # Computations
                population = __value__
                $('input[data-variable-destination="straw_population"]').val(population)
                true
      sowing:
        v00:
          seedsToSow:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-sowing-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('seeds_to_sow')
                cultivation = __procedure__.actor('cultivation')
                # Computations
                population = __value__
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * self.individualMeasure('net_mass', 'kilogram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val((population * self.individualMeasure('net_mass', 'kilogram')) / cultivation.wholeMeasure('net_surface_area', 'hectare'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val((((population * self.individualMeasure('net_mass', 'gram')) / cultivation.wholeMeasure('net_surface_area', 'square_meter')) * 1000) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val((population * self.individualMeasure('net_mass', 'gram')) / (cultivation.wholeMeasure('net_surface_area', 'hectare') * self.wholeMeasure('thousand_grains_mass', 'gram')))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val((population * self.individualMeasure('net_mass', 'gram')) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                true
            netMassKilogram:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-sowing-0.0')
                __value__ = parseFloat input.val() # :measure
                self = __procedure__.actor('seeds_to_sow')
                cultivation = __procedure__.actor('cultivation')
                # Computations
                population = __value__ / self.individualMeasure('net_mass', 'kilogram')
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val((population * self.individualMeasure('net_mass', 'kilogram')) / cultivation.wholeMeasure('net_surface_area', 'hectare'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val((((population * self.individualMeasure('net_mass', 'gram')) / cultivation.wholeMeasure('net_surface_area', 'square_meter')) * 1000) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val((population * self.individualMeasure('net_mass', 'gram')) / (cultivation.wholeMeasure('net_surface_area', 'hectare') * self.wholeMeasure('thousand_grains_mass', 'gram')))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val((population * self.individualMeasure('net_mass', 'gram')) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                true
            massAreaDensityKilogramPerHectare:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-sowing-0.0')
                __value__ = parseFloat input.val() # :measure
                self = __procedure__.actor('seeds_to_sow')
                cultivation = __procedure__.actor('cultivation')
                # Computations
                population = (__value__ * cultivation.wholeMeasure('net_surface_area', 'hectare')) / self.individualMeasure('net_mass', 'kilogram')
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * self.individualMeasure('net_mass', 'kilogram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val((((population * self.individualMeasure('net_mass', 'gram')) / cultivation.wholeMeasure('net_surface_area', 'square_meter')) * 1000) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val((population * self.individualMeasure('net_mass', 'gram')) / (cultivation.wholeMeasure('net_surface_area', 'hectare') * self.wholeMeasure('thousand_grains_mass', 'gram')))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val((population * self.individualMeasure('net_mass', 'gram')) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                true
            grainsAreaDensityUnityPerSquareMeter:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-sowing-0.0')
                __value__ = parseFloat input.val() # :measure
                self = __procedure__.actor('seeds_to_sow')
                cultivation = __procedure__.actor('cultivation')
                # Computations
                population = (((__value__ * self.wholeMeasure('thousand_grains_mass', 'gram')) / 1000) * cultivation.wholeMeasure('net_surface_area', 'square_meter')) / self.individualMeasure('net_mass', 'gram')
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * self.individualMeasure('net_mass', 'kilogram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val((population * self.individualMeasure('net_mass', 'kilogram')) / cultivation.wholeMeasure('net_surface_area', 'hectare'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val((population * self.individualMeasure('net_mass', 'gram')) / (cultivation.wholeMeasure('net_surface_area', 'hectare') * self.wholeMeasure('thousand_grains_mass', 'gram')))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val((population * self.individualMeasure('net_mass', 'gram')) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                true
            grainsAreaDensityThousandPerHectare:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-sowing-0.0')
                __value__ = parseFloat input.val() # :measure
                self = __procedure__.actor('seeds_to_sow')
                cultivation = __procedure__.actor('cultivation')
                # Computations
                population = (__value__ * self.wholeMeasure('thousand_grains_mass', 'gram') * cultivation.wholeMeasure('net_surface_area', 'hectare')) / self.individualMeasure('net_mass', 'gram')
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * self.individualMeasure('net_mass', 'kilogram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val((population * self.individualMeasure('net_mass', 'kilogram')) / cultivation.wholeMeasure('net_surface_area', 'hectare'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val((((population * self.individualMeasure('net_mass', 'gram')) / cultivation.wholeMeasure('net_surface_area', 'square_meter')) * 1000) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]').val((population * self.individualMeasure('net_mass', 'gram')) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                true
            grainsCountThousand:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-sowing-0.0')
                __value__ = parseFloat input.val() # :measure
                self = __procedure__.actor('seeds_to_sow')
                cultivation = __procedure__.actor('cultivation')
                # Computations
                population = (__value__ * self.wholeMeasure('thousand_grains_mass', 'gram')) / self.individualMeasure('net_mass', 'gram')
                $('input[data-variable-destination="seeds_to_sow_population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]').val(population)
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]').val(population * self.individualMeasure('net_mass', 'kilogram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]').val((population * self.individualMeasure('net_mass', 'kilogram')) / cultivation.wholeMeasure('net_surface_area', 'hectare'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]').val((((population * self.individualMeasure('net_mass', 'gram')) / cultivation.wholeMeasure('net_surface_area', 'square_meter')) * 1000) / self.wholeMeasure('thousand_grains_mass', 'gram'))
                $('input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]').val((population * self.individualMeasure('net_mass', 'gram')) / (cultivation.wholeMeasure('net_surface_area', 'hectare') * self.wholeMeasure('thousand_grains_mass', 'gram')))
                true
      sprayingOnCultivation:
        v00:
          medicineToSpray:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-spraying_on_cultivation-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('medicine_to_spray')
                # Computations
                population = __value__
                $('input[data-variable-destination="medicine_to_spray_population"]').val(population)
                true
      strawBunching:
        v00:
          strawBales:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-straw_bunching-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('straw_bales')
                # Computations
                population = __value__
                $('input[data-variable-destination="straw_bales_population"]').val(population)
                true
      vinePlant:
        v00:
          plantsToFix:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-vine_plant-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('plants_to_fix')
                # Computations
                population = __value__
                $('input[data-variable-destination="plants_to_fix_population"]').val(population)
                true
      wineTransfer:
        v00:
          wineToMove:
            population:
              updateOtherHandlers: (input) ->
                # Declarations
                __procedure__ = new $.Procedure('base-wine_transfer-0.0')
                __value__ = parseFloat input.val() # :decimal
                self = __procedure__.actor('wine_to_move')
                # Computations
                population = __value__
                $('input[data-variable-destination="wine_to_move_population"]').val(population)
                true
  # Adds events on inputs
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-seeds_to_sow-population"]', -> $.handlers.base.allInOneSowing.v00.seedsToSow.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-fertilizer_to_spread-population"]', -> $.handlers.base.allInOneSowing.v00.fertilizerToSpread.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-insecticide_to_input-population"]', -> $.handlers.base.allInOneSowing.v00.insecticideToInput.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-all_in_one_sowing-v0_0-moluscicide_to_input-population"]', -> $.handlers.base.allInOneSowing.v00.moluscicideToInput.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-animal_treatment-v0_0-medicine_to_give-population"]', -> $.handlers.base.animalTreatment.v00.medicineToGive.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-direct_silage-v0_0-silage-population"]', -> $.handlers.base.directSilage.v00.silage.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-grains_harvest-v0_0-grains-population"]', -> $.handlers.base.grainsHarvest.v00.grains.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-grains_harvest-v0_0-straws-population"]', -> $.handlers.base.grainsHarvest.v00.straws.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-indirect_silage-v0_0-silage-population"]', -> $.handlers.base.indirectSilage.v00.silage.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mammal_herd_milking-v0_0-milk-population"]', -> $.handlers.base.mammalHerdMilking.v00.milk.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mammal_milking-v0_0-milk-population"]', -> $.handlers.base.mammalMilking.v00.milk.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-manual_vine_harvest-v0_0-fruits-population"]', -> $.handlers.base.manualVineHarvest.v00.fruits.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mecanical_vine_harvest-v0_0-fruits-population"]', -> $.handlers.base.mecanicalVineHarvest.v00.fruits.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-mineral_fertilizing-v0_0-fertilizer_to_spread-population"]', -> $.handlers.base.mineralFertilizing.v00.fertilizerToSpread.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-organic_fertilizing-v0_0-manure_to_spread-population"]', -> $.handlers.base.organicFertilizing.v00.manureToSpread.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-partial_spraying_on_cultivation-v0_0-medicine_to_spray-population"]', -> $.handlers.base.partialSprayingOnCultivation.v00.medicineToSpray.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-partial_spraying_on_cultivation-v0_0-cultivation_to_target-shape"]', -> $.handlers.base.partialSprayingOnCultivation.v00.cultivationToTarget.shape.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-plant_grinding-v0_0-grinded-population"]', -> $.handlers.base.plantGrinding.v00.grinded.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-plant_mowing-v0_0-straw-population"]', -> $.handlers.base.plantMowing.v00.straw.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-population"]', -> $.handlers.base.sowing.v00.seedsToSow.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-net_mass-kilogram"]', -> $.handlers.base.sowing.v00.seedsToSow.netMassKilogram.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-mass_area_density-kilogram_per_hectare"]', -> $.handlers.base.sowing.v00.seedsToSow.massAreaDensityKilogramPerHectare.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-unity_per_square_meter"]', -> $.handlers.base.sowing.v00.seedsToSow.grainsAreaDensityUnityPerSquareMeter.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_area_density-thousand_per_hectare"]', -> $.handlers.base.sowing.v00.seedsToSow.grainsAreaDensityThousandPerHectare.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-sowing-v0_0-seeds_to_sow-grains_count-thousand"]', -> $.handlers.base.sowing.v00.seedsToSow.grainsCountThousand.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-spraying_on_cultivation-v0_0-medicine_to_spray-population"]', -> $.handlers.base.sprayingOnCultivation.v00.medicineToSpray.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-straw_bunching-v0_0-straw_bales-population"]', -> $.handlers.base.strawBunching.v00.strawBales.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-vine_plant-v0_0-plants_to_fix-population"]', -> $.handlers.base.vinePlant.v00.plantsToFix.population.updateOtherHandlers($(this))
  $(document).on 'keyup', 'input[data-variable-handler="base-wine_transfer-v0_0-wine_to_move-population"]', -> $.handlers.base.wineTransfer.v00.wineToMove.population.updateOtherHandlers($(this))

  true
) jQuery
