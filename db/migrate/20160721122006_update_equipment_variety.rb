# Migration generated with nomenclature migration #20160720144130
class UpdateEquipmentVariety < ActiveRecord::Migration
  def up
    # Change item varieties#item with {:name=>"equipment_part", :parent=>"matter"}
    execute "UPDATE activities SET cultivation_variety='equipment_part' WHERE cultivation_variety='item'"
    execute "UPDATE activities SET support_variety='equipment_part' WHERE support_variety='item'"
    execute "UPDATE products SET variety='equipment_part' WHERE variety='item'"
    execute "UPDATE products SET derivative_of='equipment_part' WHERE derivative_of='item'"
    execute "UPDATE product_nature_variants SET variety='equipment_part' WHERE variety='item'"
    execute "UPDATE product_nature_variants SET derivative_of='equipment_part' WHERE derivative_of='item'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='equipment_part' WHERE cultivation_variety='item'"
    execute "UPDATE product_natures SET variety='equipment_part' WHERE variety='item'"
    execute "UPDATE product_natures SET derivative_of='equipment_part' WHERE derivative_of='item'"
    # Merge item varieties#bale_collector into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='bale_collector'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='bale_collector'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='bale_collector'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='bale_collector'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='bale_collector'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='bale_collector'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='bale_collector'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='bale_collector'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='bale_collector'"
    # Merge item varieties#baler into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='baler'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='baler'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='baler'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='baler'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='baler'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='baler'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='baler'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='baler'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='baler'"
    # Merge item varieties#bottler into equipment
    execute "UPDATE activities SET cultivation_variety='equipment' WHERE cultivation_variety='bottler'"
    execute "UPDATE activities SET support_variety='equipment' WHERE support_variety='bottler'"
    execute "UPDATE products SET variety='equipment' WHERE variety='bottler'"
    execute "UPDATE products SET derivative_of='equipment' WHERE derivative_of='bottler'"
    execute "UPDATE product_nature_variants SET variety='equipment' WHERE variety='bottler'"
    execute "UPDATE product_nature_variants SET derivative_of='equipment' WHERE derivative_of='bottler'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='equipment' WHERE cultivation_variety='bottler'"
    execute "UPDATE product_natures SET variety='equipment' WHERE variety='bottler'"
    execute "UPDATE product_natures SET derivative_of='equipment' WHERE derivative_of='bottler'"
    # Merge item varieties#cleaner into portable_equipment
    execute "UPDATE activities SET cultivation_variety='portable_equipment' WHERE cultivation_variety='cleaner'"
    execute "UPDATE activities SET support_variety='portable_equipment' WHERE support_variety='cleaner'"
    execute "UPDATE products SET variety='portable_equipment' WHERE variety='cleaner'"
    execute "UPDATE products SET derivative_of='portable_equipment' WHERE derivative_of='cleaner'"
    execute "UPDATE product_nature_variants SET variety='portable_equipment' WHERE variety='cleaner'"
    execute "UPDATE product_nature_variants SET derivative_of='portable_equipment' WHERE derivative_of='cleaner'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='portable_equipment' WHERE cultivation_variety='cleaner'"
    execute "UPDATE product_natures SET variety='portable_equipment' WHERE variety='cleaner'"
    execute "UPDATE product_natures SET derivative_of='portable_equipment' WHERE derivative_of='cleaner'"
    # Merge item varieties#corker into equipment
    execute "UPDATE activities SET cultivation_variety='equipment' WHERE cultivation_variety='corker'"
    execute "UPDATE activities SET support_variety='equipment' WHERE support_variety='corker'"
    execute "UPDATE products SET variety='equipment' WHERE variety='corker'"
    execute "UPDATE products SET derivative_of='equipment' WHERE derivative_of='corker'"
    execute "UPDATE product_nature_variants SET variety='equipment' WHERE variety='corker'"
    execute "UPDATE product_nature_variants SET derivative_of='equipment' WHERE derivative_of='corker'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='equipment' WHERE cultivation_variety='corker'"
    execute "UPDATE product_natures SET variety='equipment' WHERE variety='corker'"
    execute "UPDATE product_natures SET derivative_of='equipment' WHERE derivative_of='corker'"
    # Merge item varieties#food_deliver into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='food_deliver'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='food_deliver'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='food_deliver'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='food_deliver'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='food_deliver'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='food_deliver'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='food_deliver'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='food_deliver'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='food_deliver'"
    # Merge item varieties#forager into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='forager'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='forager'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='forager'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='forager'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='forager'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='forager'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='forager'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='forager'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='forager'"
    # Merge item varieties#harvester into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='harvester'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='harvester'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='harvester'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='harvester'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='harvester'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='harvester'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='harvester'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='harvester'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='harvester'"
    # Merge item varieties#implanter into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='implanter'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='implanter'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='implanter'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='implanter'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='implanter'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='implanter'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='implanter'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='implanter'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='implanter'"
    # Merge item varieties#mower into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='mower'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='mower'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='mower'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='mower'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='mower'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='mower'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='mower'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='mower'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='mower'"
    # Merge item varieties#plower into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='plower'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='plower'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='plower'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='plower'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='plower'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='plower'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='plower'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='plower'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='plower'"
    # Merge item varieties#press into equipment
    execute "UPDATE activities SET cultivation_variety='equipment' WHERE cultivation_variety='press'"
    execute "UPDATE activities SET support_variety='equipment' WHERE support_variety='press'"
    execute "UPDATE products SET variety='equipment' WHERE variety='press'"
    execute "UPDATE products SET derivative_of='equipment' WHERE derivative_of='press'"
    execute "UPDATE product_nature_variants SET variety='equipment' WHERE variety='press'"
    execute "UPDATE product_nature_variants SET derivative_of='equipment' WHERE derivative_of='press'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='equipment' WHERE cultivation_variety='press'"
    execute "UPDATE product_natures SET variety='equipment' WHERE variety='press'"
    execute "UPDATE product_natures SET derivative_of='equipment' WHERE derivative_of='press'"
    # Merge item varieties#pruner into portable_equipment
    execute "UPDATE activities SET cultivation_variety='portable_equipment' WHERE cultivation_variety='pruner'"
    execute "UPDATE activities SET support_variety='portable_equipment' WHERE support_variety='pruner'"
    execute "UPDATE products SET variety='portable_equipment' WHERE variety='pruner'"
    execute "UPDATE products SET derivative_of='portable_equipment' WHERE derivative_of='pruner'"
    execute "UPDATE product_nature_variants SET variety='portable_equipment' WHERE variety='pruner'"
    execute "UPDATE product_nature_variants SET derivative_of='portable_equipment' WHERE derivative_of='pruner'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='portable_equipment' WHERE cultivation_variety='pruner'"
    execute "UPDATE product_natures SET variety='portable_equipment' WHERE variety='pruner'"
    execute "UPDATE product_natures SET derivative_of='portable_equipment' WHERE derivative_of='pruner'"
    # Merge item varieties#reaper into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='reaper'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='reaper'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='reaper'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='reaper'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='reaper'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='reaper'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='reaper'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='reaper'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='reaper'"
    # Merge item varieties#sower into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='sower'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='sower'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='sower'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='sower'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='sower'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='sower'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='sower'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='sower'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='sower'"
    # Merge item varieties#sprayer into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='sprayer'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='sprayer'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='sprayer'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='sprayer'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='sprayer'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='sprayer'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='sprayer'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='sprayer'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='sprayer'"
    # Merge item varieties#spreader into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='spreader'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='spreader'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='spreader'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='spreader'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='spreader'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='spreader'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='spreader'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='spreader'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='spreader'"
    # Merge item varieties#telescopic_handler into handling_equipment
    execute "UPDATE activities SET cultivation_variety='handling_equipment' WHERE cultivation_variety='telescopic_handler'"
    execute "UPDATE activities SET support_variety='handling_equipment' WHERE support_variety='telescopic_handler'"
    execute "UPDATE products SET variety='handling_equipment' WHERE variety='telescopic_handler'"
    execute "UPDATE products SET derivative_of='handling_equipment' WHERE derivative_of='telescopic_handler'"
    execute "UPDATE product_nature_variants SET variety='handling_equipment' WHERE variety='telescopic_handler'"
    execute "UPDATE product_nature_variants SET derivative_of='handling_equipment' WHERE derivative_of='telescopic_handler'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='handling_equipment' WHERE cultivation_variety='telescopic_handler'"
    execute "UPDATE product_natures SET variety='handling_equipment' WHERE variety='telescopic_handler'"
    execute "UPDATE product_natures SET derivative_of='handling_equipment' WHERE derivative_of='telescopic_handler'"
    # Merge item varieties#trailer into trailed_equipment
    execute "UPDATE activities SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='trailer'"
    execute "UPDATE activities SET support_variety='trailed_equipment' WHERE support_variety='trailer'"
    execute "UPDATE products SET variety='trailed_equipment' WHERE variety='trailer'"
    execute "UPDATE products SET derivative_of='trailed_equipment' WHERE derivative_of='trailer'"
    execute "UPDATE product_nature_variants SET variety='trailed_equipment' WHERE variety='trailer'"
    execute "UPDATE product_nature_variants SET derivative_of='trailed_equipment' WHERE derivative_of='trailer'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='trailed_equipment' WHERE cultivation_variety='trailer'"
    execute "UPDATE product_natures SET variety='trailed_equipment' WHERE variety='trailer'"
    execute "UPDATE product_natures SET derivative_of='trailed_equipment' WHERE derivative_of='trailer'"
    # Merge item varieties#wheel_loader into heavy_equipment
    execute "UPDATE activities SET cultivation_variety='heavy_equipment' WHERE cultivation_variety='wheel_loader'"
    execute "UPDATE activities SET support_variety='heavy_equipment' WHERE support_variety='wheel_loader'"
    execute "UPDATE products SET variety='heavy_equipment' WHERE variety='wheel_loader'"
    execute "UPDATE products SET derivative_of='heavy_equipment' WHERE derivative_of='wheel_loader'"
    execute "UPDATE product_nature_variants SET variety='heavy_equipment' WHERE variety='wheel_loader'"
    execute "UPDATE product_nature_variants SET derivative_of='heavy_equipment' WHERE derivative_of='wheel_loader'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='heavy_equipment' WHERE cultivation_variety='wheel_loader'"
    execute "UPDATE product_natures SET variety='heavy_equipment' WHERE variety='wheel_loader'"
    execute "UPDATE product_natures SET derivative_of='heavy_equipment' WHERE derivative_of='wheel_loader'"
  end

  def down
    # Reverse: Merge item varieties#wheel_loader into heavy_equipment
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in product_natures#derivative_of
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in product_natures#variety
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in product_nature_variants#variety
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in products#derivative_of
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in products#variety
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in activities#support_variety
    # Cannot unmerge 'wheel_loader' from 'heavy_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#trailer into trailed_equipment
    # Cannot unmerge 'trailer' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'trailer' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'trailer' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'trailer' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'trailer' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'trailer' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'trailer' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'trailer' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'trailer' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#telescopic_handler into handling_equipment
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in product_natures#derivative_of
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in product_natures#variety
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in product_nature_variants#variety
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in products#derivative_of
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in products#variety
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in activities#support_variety
    # Cannot unmerge 'telescopic_handler' from 'handling_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#spreader into trailed_equipment
    # Cannot unmerge 'spreader' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'spreader' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'spreader' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'spreader' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'spreader' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'spreader' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'spreader' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'spreader' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'spreader' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#sprayer into trailed_equipment
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'sprayer' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#sower into trailed_equipment
    # Cannot unmerge 'sower' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'sower' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'sower' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'sower' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'sower' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'sower' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'sower' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'sower' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'sower' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#reaper into trailed_equipment
    # Cannot unmerge 'reaper' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'reaper' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'reaper' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'reaper' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'reaper' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'reaper' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'reaper' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'reaper' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'reaper' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#pruner into portable_equipment
    # Cannot unmerge 'pruner' from 'portable_equipment' in product_natures#derivative_of
    # Cannot unmerge 'pruner' from 'portable_equipment' in product_natures#variety
    # Cannot unmerge 'pruner' from 'portable_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'pruner' from 'portable_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'pruner' from 'portable_equipment' in product_nature_variants#variety
    # Cannot unmerge 'pruner' from 'portable_equipment' in products#derivative_of
    # Cannot unmerge 'pruner' from 'portable_equipment' in products#variety
    # Cannot unmerge 'pruner' from 'portable_equipment' in activities#support_variety
    # Cannot unmerge 'pruner' from 'portable_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#press into equipment
    # Cannot unmerge 'press' from 'equipment' in product_natures#derivative_of
    # Cannot unmerge 'press' from 'equipment' in product_natures#variety
    # Cannot unmerge 'press' from 'equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'press' from 'equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'press' from 'equipment' in product_nature_variants#variety
    # Cannot unmerge 'press' from 'equipment' in products#derivative_of
    # Cannot unmerge 'press' from 'equipment' in products#variety
    # Cannot unmerge 'press' from 'equipment' in activities#support_variety
    # Cannot unmerge 'press' from 'equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#plower into trailed_equipment
    # Cannot unmerge 'plower' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'plower' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'plower' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'plower' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'plower' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'plower' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'plower' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'plower' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'plower' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#mower into trailed_equipment
    # Cannot unmerge 'mower' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'mower' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'mower' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'mower' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'mower' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'mower' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'mower' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'mower' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'mower' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#implanter into trailed_equipment
    # Cannot unmerge 'implanter' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'implanter' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'implanter' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'implanter' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'implanter' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'implanter' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'implanter' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'implanter' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'implanter' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#harvester into trailed_equipment
    # Cannot unmerge 'harvester' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'harvester' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'harvester' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'harvester' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'harvester' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'harvester' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'harvester' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'harvester' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'harvester' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#forager into trailed_equipment
    # Cannot unmerge 'forager' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'forager' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'forager' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'forager' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'forager' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'forager' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'forager' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'forager' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'forager' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#food_deliver into trailed_equipment
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'food_deliver' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#corker into equipment
    # Cannot unmerge 'corker' from 'equipment' in product_natures#derivative_of
    # Cannot unmerge 'corker' from 'equipment' in product_natures#variety
    # Cannot unmerge 'corker' from 'equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'corker' from 'equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'corker' from 'equipment' in product_nature_variants#variety
    # Cannot unmerge 'corker' from 'equipment' in products#derivative_of
    # Cannot unmerge 'corker' from 'equipment' in products#variety
    # Cannot unmerge 'corker' from 'equipment' in activities#support_variety
    # Cannot unmerge 'corker' from 'equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#cleaner into portable_equipment
    # Cannot unmerge 'cleaner' from 'portable_equipment' in product_natures#derivative_of
    # Cannot unmerge 'cleaner' from 'portable_equipment' in product_natures#variety
    # Cannot unmerge 'cleaner' from 'portable_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'cleaner' from 'portable_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'cleaner' from 'portable_equipment' in product_nature_variants#variety
    # Cannot unmerge 'cleaner' from 'portable_equipment' in products#derivative_of
    # Cannot unmerge 'cleaner' from 'portable_equipment' in products#variety
    # Cannot unmerge 'cleaner' from 'portable_equipment' in activities#support_variety
    # Cannot unmerge 'cleaner' from 'portable_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#bottler into equipment
    # Cannot unmerge 'bottler' from 'equipment' in product_natures#derivative_of
    # Cannot unmerge 'bottler' from 'equipment' in product_natures#variety
    # Cannot unmerge 'bottler' from 'equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'bottler' from 'equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'bottler' from 'equipment' in product_nature_variants#variety
    # Cannot unmerge 'bottler' from 'equipment' in products#derivative_of
    # Cannot unmerge 'bottler' from 'equipment' in products#variety
    # Cannot unmerge 'bottler' from 'equipment' in activities#support_variety
    # Cannot unmerge 'bottler' from 'equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#baler into trailed_equipment
    # Cannot unmerge 'baler' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'baler' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'baler' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'baler' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'baler' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'baler' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'baler' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'baler' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'baler' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Merge item varieties#bale_collector into trailed_equipment
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in product_natures#derivative_of
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in product_natures#variety
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in product_nature_variants#derivative_of
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in product_nature_variants#variety
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in products#derivative_of
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in products#variety
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in activities#support_variety
    # Cannot unmerge 'bale_collector' from 'trailed_equipment' in activities#cultivation_variety
    # Reverse: Change item varieties#item with {:name=>"equipment_part", :parent=>"matter"}
    execute "UPDATE product_natures SET derivative_of='item' WHERE derivative_of='equipment_part'"
    execute "UPDATE product_natures SET variety='item' WHERE variety='equipment_part'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='item' WHERE cultivation_variety='equipment_part'"
    execute "UPDATE product_nature_variants SET derivative_of='item' WHERE derivative_of='equipment_part'"
    execute "UPDATE product_nature_variants SET variety='item' WHERE variety='equipment_part'"
    execute "UPDATE products SET derivative_of='item' WHERE derivative_of='equipment_part'"
    execute "UPDATE products SET variety='item' WHERE variety='equipment_part'"
    execute "UPDATE activities SET support_variety='item' WHERE support_variety='equipment_part'"
    execute "UPDATE activities SET cultivation_variety='item' WHERE cultivation_variety='equipment_part'"
  end
end
