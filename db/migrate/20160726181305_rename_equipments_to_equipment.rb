# Migration generated with nomenclature migration #20160726173309
class RenameEquipmentsToEquipment < ActiveRecord::Migration
  def up
    # Change item accounts#equipment_expenses with {:name=>"equipment_maintenance_expenses"}
    execute "UPDATE accounts SET usages = REGEXP_REPLACE(usages, E'\\\\mequipment_expenses\\\\M', 'equipment_maintenance_expenses', 'g')"
    # Change item accounts#equipments_expenses with {:name=>"equipment_expenses"}
    execute "UPDATE accounts SET usages = REGEXP_REPLACE(usages, E'\\\\mequipments_expenses\\\\M', 'equipment_expenses', 'g')"
    # Change item accounts#equipments_depreciations_inputations_expenses with {:name=>"equipment_depreciations_inputations_expenses"}
    execute "UPDATE accounts SET usages = REGEXP_REPLACE(usages, E'\\\\mequipments_depreciations_inputations_expenses\\\\M', 'equipment_depreciations_inputations_expenses', 'g')"
  end

  def down
    # Reverse: Change item accounts#equipments_depreciations_inputations_expenses with {:name=>"equipment_depreciations_inputations_expenses"}
    execute "UPDATE accounts SET usages = REGEXP_REPLACE(usages, E'\\\\mequipment_depreciations_inputations_expenses\\\\M', 'equipments_depreciations_inputations_expenses', 'g')"
    # Reverse: Change item accounts#equipments_expenses with {:name=>"equipment_expenses"}
    execute "UPDATE accounts SET usages = REGEXP_REPLACE(usages, E'\\\\mequipment_expenses\\\\M', 'equipments_expenses', 'g')"
    # Reverse: Change item accounts#equipment_expenses with {:name=>"equipment_maintenance_expenses"}
    execute "UPDATE accounts SET usages = REGEXP_REPLACE(usages, E'\\\\mequipment_maintenance_expenses\\\\M', 'equipment_expenses', 'g')"
  end
end
