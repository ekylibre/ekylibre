# Migration generated with nomenclature migration #20160206163031
class SimplifiesActivityFamily < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        # Change item activity_families#administrative with {:name=>"administering", :parent=>nil}
        execute "UPDATE activities SET family='administering' WHERE family='administrative'"
        # Merge item activity_families#accountancy into administering
        execute "UPDATE activities SET family='administering' WHERE family='accountancy'"
        # Merge item activity_families#sales into administering
        execute "UPDATE activities SET family='administering' WHERE family='sales'"
        # Merge item activity_families#purchases into administering
        execute "UPDATE activities SET family='administering' WHERE family='purchases'"
        # Merge item activity_families#stocks into administering
        execute "UPDATE activities SET family='administering' WHERE family='stocks'"
        # Merge item activity_families#exploitation into administering
        execute "UPDATE activities SET family='administering' WHERE family='exploitation'"
        # Change item activity_families#maintenance with {:name=>"tool_maintaining", :cultivation_variety=>nil}
        execute "UPDATE activities SET family='tool_maintaining' WHERE family='maintenance'"
        # Merge item activity_families#equipment_management into tool_maintaining
        execute "UPDATE activities SET family='tool_maintaining' WHERE family='equipment_management'"
        # Change item activity_families#wine with {:name=>"wine_making"}
        execute "UPDATE activities SET family='wine_making' WHERE family='wine'"
        # Change item activity_families#service with {:name=>"service_delivering"}
        execute "UPDATE activities SET family='service_delivering' WHERE family='service'"
        # Merge item activity_families#animal_housing into service_delivering
        execute "UPDATE activities SET family='service_delivering' WHERE family='animal_housing'"
        # Merge item activity_families#catering into service_delivering
        execute "UPDATE activities SET family='service_delivering' WHERE family='catering'"
        # Merge item activity_families#lodging into service_delivering
        execute "UPDATE activities SET family='service_delivering' WHERE family='lodging'"
        # Merge item activity_families#renting into service_delivering
        execute "UPDATE activities SET family='service_delivering' WHERE family='renting'"
        # Merge item activity_families#agricultural_works into service_delivering
        execute "UPDATE activities SET family='service_delivering' WHERE family='agricultural_works'"
        # Merge item activity_families#building_works into service_delivering
        execute "UPDATE activities SET family='service_delivering' WHERE family='building_works'"
        # Merge item activity_families#works into service_delivering
        execute "UPDATE activities SET family='service_delivering' WHERE family='works'"
        # Merge item activity_families#beekeeping into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='beekeeping'"
        # Merge item activity_families#cattle_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='cattle_farming'"
        # Merge item activity_families#bison_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='bison_farming'"
        # Merge item activity_families#goat_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='goat_farming'"
        # Merge item activity_families#ostrich_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='ostrich_farming'"
        # Merge item activity_families#oyster_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='oyster_farming'"
        # Merge item activity_families#palmiped_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='palmiped_farming'"
        # Merge item activity_families#pig_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='pig_farming'"
        # Merge item activity_families#poultry_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='poultry_farming'"
        # Merge item activity_families#rabbit_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='rabbit_farming'"
        # Merge item activity_families#salmon_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='salmon_farming'"
        # Merge item activity_families#scallop_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='scallop_farming'"
        # Merge item activity_families#sheep_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='sheep_farming'"
        # Merge item activity_families#snail_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='snail_farming'"
        # Merge item activity_families#sturgeon_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='sturgeon_farming'"
        # Merge item activity_families#mussel_farming into animal_farming
        execute "UPDATE activities SET family='animal_farming' WHERE family='mussel_farming'"
        # Change item activity_families#vegetal_crops with {:name=>"plant_farming"}
        execute "UPDATE activities SET family='plant_farming' WHERE family='vegetal_crops'"
        # Merge item activity_families#alfalfa_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='alfalfa_crops'"
        # Merge item activity_families#almond_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='almond_orchards'"
        # Merge item activity_families#apple_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='apple_orchards'"
        # Merge item activity_families#arboriculture into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='arboriculture'"
        # Merge item activity_families#aromatic_and_medicinal_plants into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='aromatic_and_medicinal_plants'"
        # Merge item activity_families#artichoke_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='artichoke_crops'"
        # Merge item activity_families#asparagus_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='asparagus_crops'"
        # Merge item activity_families#avocado_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='avocado_crops'"
        # Merge item activity_families#barley_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='barley_crops'"
        # Merge item activity_families#bean_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='bean_crops'"
        # Merge item activity_families#beet_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='beet_crops'"
        # Merge item activity_families#bere_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='bere_crops'"
        # Merge item activity_families#black_mustard_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='black_mustard_crops'"
        # Merge item activity_families#blackcurrant_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='blackcurrant_crops'"
        # Merge item activity_families#cabbage_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='cabbage_crops'"
        # Merge item activity_families#canary_grass_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='canary_grass_crops'"
        # Merge item activity_families#carob_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='carob_orchards'"
        # Merge item activity_families#carrot_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='carrot_crops'"
        # Merge item activity_families#celery_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='celery_crops'"
        # Merge item activity_families#cereal_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='cereal_crops'"
        # Merge item activity_families#chestnut_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='chestnut_orchards'"
        # Merge item activity_families#chickpea_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='chickpea_crops'"
        # Merge item activity_families#chicory_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='chicory_crops'"
        # Merge item activity_families#cichorium_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='cichorium_crops'"
        # Merge item activity_families#citrus_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='citrus_orchards'"
        # Merge item activity_families#cocoa_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='cocoa_crops'"
        # Merge item activity_families#common_wheat_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='common_wheat_crops'"
        # Merge item activity_families#cotton_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='cotton_crops'"
        # Merge item activity_families#durum_wheat_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='durum_wheat_crops'"
        # Merge item activity_families#eggplant_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='eggplant_crops'"
        # Merge item activity_families#fallow_land into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='fallow_land'"
        # Merge item activity_families#field_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='field_crops'"
        # Merge item activity_families#flax_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='flax_crops'"
        # Merge item activity_families#flower_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='flower_crops'"
        # Merge item activity_families#fodder_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='fodder_crops'"
        # Merge item activity_families#fruits_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='fruits_crops'"
        # Merge item activity_families#garden_pea_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='garden_pea_crops'"
        # Merge item activity_families#garlic_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='garlic_crops'"
        # Merge item activity_families#hazel_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='hazel_orchards'"
        # Merge item activity_families#hemp_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='hemp_crops'"
        # Merge item activity_families#hop_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='hop_crops'"
        # Merge item activity_families#horsebean_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='horsebean_crops'"
        # Merge item activity_families#lavender_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='lavender_crops'"
        # Merge item activity_families#leek_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='leek_crops'"
        # Merge item activity_families#leguminous_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='leguminous_crops'"
        # Merge item activity_families#lentil_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='lentil_crops'"
        # Merge item activity_families#lettuce_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='lettuce_crops'"
        # Merge item activity_families#lupin_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='lupin_crops'"
        # Merge item activity_families#maize_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='maize_crops'"
        # Merge item activity_families#market_garden_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='market_garden_crops'"
        # Merge item activity_families#meadow into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='meadow'"
        # Merge item activity_families#muskmelon_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='muskmelon_crops'"
        # Merge item activity_families#oat_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='oat_crops'"
        # Merge item activity_families#oilseed_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='oilseed_crops'"
        # Merge item activity_families#olive_groves into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='olive_groves'"
        # Merge item activity_families#olive_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='olive_orchards'"
        # Merge item activity_families#onion_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='onion_crops'"
        # Merge item activity_families#parsley_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='parsley_crops'"
        # Merge item activity_families#pea_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='pea_crops'"
        # Merge item activity_families#peach_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='peach_orchards'"
        # Merge item activity_families#peanut_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='peanut_crops'"
        # Merge item activity_families#pear_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='pear_orchards'"
        # Merge item activity_families#pineapple_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='pineapple_crops'"
        # Merge item activity_families#pistachio_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='pistachio_orchards'"
        # Merge item activity_families#plum_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='plum_orchards'"
        # Merge item activity_families#poaceae_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='poaceae_crops'"
        # Merge item activity_families#potato_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='potato_crops'"
        # Merge item activity_families#protein_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='protein_crops'"
        # Merge item activity_families#radish_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='radish_crops'"
        # Merge item activity_families#rapeseed_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='rapeseed_crops'"
        # Merge item activity_families#raspberry_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='raspberry_crops'"
        # Merge item activity_families#redcurrant_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='redcurrant_crops'"
        # Merge item activity_families#rice_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='rice_crops'"
        # Merge item activity_families#rye_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='rye_crops'"
        # Merge item activity_families#saffron_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='saffron_crops'"
        # Merge item activity_families#sorghum_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='sorghum_crops'"
        # Merge item activity_families#soybean_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='soybean_crops'"
        # Merge item activity_families#strawberry_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='strawberry_crops'"
        # Merge item activity_families#sunflower_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='sunflower_crops'"
        # Merge item activity_families#tobacco_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='tobacco_crops'"
        # Merge item activity_families#tomato_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='tomato_crops'"
        # Merge item activity_families#triticale_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='triticale_crops'"
        # Merge item activity_families#turnip_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='turnip_crops'"
        # Merge item activity_families#vetch_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='vetch_crops'"
        # Merge item activity_families#vines into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='vines'"
        # Merge item activity_families#walnut_orchards into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='walnut_orchards'"
        # Merge item activity_families#watermelon_crops into plant_farming
        execute "UPDATE activities SET family='plant_farming' WHERE family='watermelon_crops'"
        # Change item document_categories#vegetal_crops with {:name=>"plant_farming"}
        # Change item document_categories#vinification with {:name=>"wine_making"}
        # Change item document_categories#transformation with {:name=>"processing"}
      end
      dir.down do
        # Reverse: Change item document_categories#transformation with {:name=>"processing"}
        # Reverse: Change item document_categories#vinification with {:name=>"wine_making"}
        # Reverse: Change item document_categories#vegetal_crops with {:name=>"plant_farming"}
        # Reverse: Merge item activity_families#watermelon_crops into plant_farming
        # Cannot unmerge 'watermelon_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#walnut_orchards into plant_farming
        # Cannot unmerge 'walnut_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#vines into plant_farming
        # Cannot unmerge 'vines' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#vetch_crops into plant_farming
        # Cannot unmerge 'vetch_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#turnip_crops into plant_farming
        # Cannot unmerge 'turnip_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#triticale_crops into plant_farming
        # Cannot unmerge 'triticale_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#tomato_crops into plant_farming
        # Cannot unmerge 'tomato_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#tobacco_crops into plant_farming
        # Cannot unmerge 'tobacco_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#sunflower_crops into plant_farming
        # Cannot unmerge 'sunflower_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#strawberry_crops into plant_farming
        # Cannot unmerge 'strawberry_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#soybean_crops into plant_farming
        # Cannot unmerge 'soybean_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#sorghum_crops into plant_farming
        # Cannot unmerge 'sorghum_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#saffron_crops into plant_farming
        # Cannot unmerge 'saffron_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#rye_crops into plant_farming
        # Cannot unmerge 'rye_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#rice_crops into plant_farming
        # Cannot unmerge 'rice_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#redcurrant_crops into plant_farming
        # Cannot unmerge 'redcurrant_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#raspberry_crops into plant_farming
        # Cannot unmerge 'raspberry_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#rapeseed_crops into plant_farming
        # Cannot unmerge 'rapeseed_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#radish_crops into plant_farming
        # Cannot unmerge 'radish_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#protein_crops into plant_farming
        # Cannot unmerge 'protein_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#potato_crops into plant_farming
        # Cannot unmerge 'potato_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#poaceae_crops into plant_farming
        # Cannot unmerge 'poaceae_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#plum_orchards into plant_farming
        # Cannot unmerge 'plum_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#pistachio_orchards into plant_farming
        # Cannot unmerge 'pistachio_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#pineapple_crops into plant_farming
        # Cannot unmerge 'pineapple_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#pear_orchards into plant_farming
        # Cannot unmerge 'pear_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#peanut_crops into plant_farming
        # Cannot unmerge 'peanut_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#peach_orchards into plant_farming
        # Cannot unmerge 'peach_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#pea_crops into plant_farming
        # Cannot unmerge 'pea_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#parsley_crops into plant_farming
        # Cannot unmerge 'parsley_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#onion_crops into plant_farming
        # Cannot unmerge 'onion_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#olive_orchards into plant_farming
        # Cannot unmerge 'olive_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#olive_groves into plant_farming
        # Cannot unmerge 'olive_groves' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#oilseed_crops into plant_farming
        # Cannot unmerge 'oilseed_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#oat_crops into plant_farming
        # Cannot unmerge 'oat_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#muskmelon_crops into plant_farming
        # Cannot unmerge 'muskmelon_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#meadow into plant_farming
        # Cannot unmerge 'meadow' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#market_garden_crops into plant_farming
        # Cannot unmerge 'market_garden_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#maize_crops into plant_farming
        # Cannot unmerge 'maize_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#lupin_crops into plant_farming
        # Cannot unmerge 'lupin_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#lettuce_crops into plant_farming
        # Cannot unmerge 'lettuce_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#lentil_crops into plant_farming
        # Cannot unmerge 'lentil_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#leguminous_crops into plant_farming
        # Cannot unmerge 'leguminous_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#leek_crops into plant_farming
        # Cannot unmerge 'leek_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#lavender_crops into plant_farming
        # Cannot unmerge 'lavender_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#horsebean_crops into plant_farming
        # Cannot unmerge 'horsebean_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#hop_crops into plant_farming
        # Cannot unmerge 'hop_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#hemp_crops into plant_farming
        # Cannot unmerge 'hemp_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#hazel_orchards into plant_farming
        # Cannot unmerge 'hazel_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#garlic_crops into plant_farming
        # Cannot unmerge 'garlic_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#garden_pea_crops into plant_farming
        # Cannot unmerge 'garden_pea_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#fruits_crops into plant_farming
        # Cannot unmerge 'fruits_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#fodder_crops into plant_farming
        # Cannot unmerge 'fodder_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#flower_crops into plant_farming
        # Cannot unmerge 'flower_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#flax_crops into plant_farming
        # Cannot unmerge 'flax_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#field_crops into plant_farming
        # Cannot unmerge 'field_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#fallow_land into plant_farming
        # Cannot unmerge 'fallow_land' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#eggplant_crops into plant_farming
        # Cannot unmerge 'eggplant_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#durum_wheat_crops into plant_farming
        # Cannot unmerge 'durum_wheat_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#cotton_crops into plant_farming
        # Cannot unmerge 'cotton_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#common_wheat_crops into plant_farming
        # Cannot unmerge 'common_wheat_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#cocoa_crops into plant_farming
        # Cannot unmerge 'cocoa_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#citrus_orchards into plant_farming
        # Cannot unmerge 'citrus_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#cichorium_crops into plant_farming
        # Cannot unmerge 'cichorium_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#chicory_crops into plant_farming
        # Cannot unmerge 'chicory_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#chickpea_crops into plant_farming
        # Cannot unmerge 'chickpea_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#chestnut_orchards into plant_farming
        # Cannot unmerge 'chestnut_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#cereal_crops into plant_farming
        # Cannot unmerge 'cereal_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#celery_crops into plant_farming
        # Cannot unmerge 'celery_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#carrot_crops into plant_farming
        # Cannot unmerge 'carrot_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#carob_orchards into plant_farming
        # Cannot unmerge 'carob_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#canary_grass_crops into plant_farming
        # Cannot unmerge 'canary_grass_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#cabbage_crops into plant_farming
        # Cannot unmerge 'cabbage_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#blackcurrant_crops into plant_farming
        # Cannot unmerge 'blackcurrant_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#black_mustard_crops into plant_farming
        # Cannot unmerge 'black_mustard_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#bere_crops into plant_farming
        # Cannot unmerge 'bere_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#beet_crops into plant_farming
        # Cannot unmerge 'beet_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#bean_crops into plant_farming
        # Cannot unmerge 'bean_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#barley_crops into plant_farming
        # Cannot unmerge 'barley_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#avocado_crops into plant_farming
        # Cannot unmerge 'avocado_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#asparagus_crops into plant_farming
        # Cannot unmerge 'asparagus_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#artichoke_crops into plant_farming
        # Cannot unmerge 'artichoke_crops' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#aromatic_and_medicinal_plants into plant_farming
        # Cannot unmerge 'aromatic_and_medicinal_plants' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#arboriculture into plant_farming
        # Cannot unmerge 'arboriculture' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#apple_orchards into plant_farming
        # Cannot unmerge 'apple_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#almond_orchards into plant_farming
        # Cannot unmerge 'almond_orchards' from 'plant_farming' in activities#family
        # Reverse: Merge item activity_families#alfalfa_crops into plant_farming
        # Cannot unmerge 'alfalfa_crops' from 'plant_farming' in activities#family
        # Reverse: Change item activity_families#vegetal_crops with {:name=>"plant_farming"}
        execute "UPDATE activities SET family='vegetal_crops' WHERE family='plant_farming'"
        # Reverse: Merge item activity_families#mussel_farming into animal_farming
        # Cannot unmerge 'mussel_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#sturgeon_farming into animal_farming
        # Cannot unmerge 'sturgeon_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#snail_farming into animal_farming
        # Cannot unmerge 'snail_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#sheep_farming into animal_farming
        # Cannot unmerge 'sheep_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#scallop_farming into animal_farming
        # Cannot unmerge 'scallop_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#salmon_farming into animal_farming
        # Cannot unmerge 'salmon_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#rabbit_farming into animal_farming
        # Cannot unmerge 'rabbit_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#poultry_farming into animal_farming
        # Cannot unmerge 'poultry_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#pig_farming into animal_farming
        # Cannot unmerge 'pig_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#palmiped_farming into animal_farming
        # Cannot unmerge 'palmiped_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#oyster_farming into animal_farming
        # Cannot unmerge 'oyster_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#ostrich_farming into animal_farming
        # Cannot unmerge 'ostrich_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#goat_farming into animal_farming
        # Cannot unmerge 'goat_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#bison_farming into animal_farming
        # Cannot unmerge 'bison_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#cattle_farming into animal_farming
        # Cannot unmerge 'cattle_farming' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#beekeeping into animal_farming
        # Cannot unmerge 'beekeeping' from 'animal_farming' in activities#family
        # Reverse: Merge item activity_families#works into service_delivering
        # Cannot unmerge 'works' from 'service_delivering' in activities#family
        # Reverse: Merge item activity_families#building_works into service_delivering
        # Cannot unmerge 'building_works' from 'service_delivering' in activities#family
        # Reverse: Merge item activity_families#agricultural_works into service_delivering
        # Cannot unmerge 'agricultural_works' from 'service_delivering' in activities#family
        # Reverse: Merge item activity_families#renting into service_delivering
        # Cannot unmerge 'renting' from 'service_delivering' in activities#family
        # Reverse: Merge item activity_families#lodging into service_delivering
        # Cannot unmerge 'lodging' from 'service_delivering' in activities#family
        # Reverse: Merge item activity_families#catering into service_delivering
        # Cannot unmerge 'catering' from 'service_delivering' in activities#family
        # Reverse: Merge item activity_families#animal_housing into service_delivering
        # Cannot unmerge 'animal_housing' from 'service_delivering' in activities#family
        # Reverse: Change item activity_families#service with {:name=>"service_delivering"}
        execute "UPDATE activities SET family='service' WHERE family='service_delivering'"
        # Reverse: Change item activity_families#wine with {:name=>"wine_making"}
        execute "UPDATE activities SET family='wine' WHERE family='wine_making'"
        # Reverse: Merge item activity_families#equipment_management into tool_maintaining
        # Cannot unmerge 'equipment_management' from 'tool_maintaining' in activities#family
        # Reverse: Change item activity_families#maintenance with {:name=>"tool_maintaining", :cultivation_variety=>nil}
        execute "UPDATE activities SET family='maintenance' WHERE family='tool_maintaining'"
        # Reverse: Merge item activity_families#exploitation into administering
        # Cannot unmerge 'exploitation' from 'administering' in activities#family
        # Reverse: Merge item activity_families#stocks into administering
        # Cannot unmerge 'stocks' from 'administering' in activities#family
        # Reverse: Merge item activity_families#purchases into administering
        # Cannot unmerge 'purchases' from 'administering' in activities#family
        # Reverse: Merge item activity_families#sales into administering
        # Cannot unmerge 'sales' from 'administering' in activities#family
        # Reverse: Merge item activity_families#accountancy into administering
        # Cannot unmerge 'accountancy' from 'administering' in activities#family
        # Reverse: Change item activity_families#administrative with {:name=>"administering", :parent=>nil}
        execute "UPDATE activities SET family='administrative' WHERE family='administering'"
      end
    end
  end
end
