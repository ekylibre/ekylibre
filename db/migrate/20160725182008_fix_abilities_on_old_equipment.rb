class FixAbilitiesOnOldEquipment < ActiveRecord::Migration
  VARIETY_RENAMINGS = {
    bale_collector: :trailed_equipment,
    baler: :trailed_equipment,
    bottler: :equipment,
    cleaner: :portable_equipment,
    corker: :equipment,
    food_deliver: :trailed_equipment,
    forager: :trailed_equipment,
    harvester: :trailed_equipment,
    implanter: :trailed_equipment,
    mower: :trailed_equipment,
    plower: :trailed_equipment,
    press: :equipment,
    pruner: :portable_equipment,
    reaper: :trailed_equipment,
    sower: :trailed_equipment,
    sprayer: :trailed_equipment,
    spreader: :trailed_equipment,
    telescopic_handler: :handling_equipment,
    trailer: :trailed_equipment,
    wheel_loader: :heavy_equipment
  }.freeze

  def up
    VARIETY_RENAMINGS.each do |o, n|
      execute "UPDATE product_natures SET abilities_list = REPLACE(abilities_list, '(#{o})', '(#{n})')"
      execute "UPDATE product_natures SET abilities_list = REPLACE(abilities_list, ', #{o})', ', #{n})')"
    end
  end

  def down
    # Not really reversible...
  end
end
