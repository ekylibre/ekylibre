class RenameProcedures < ActiveRecord::Migration
  def change
    # Rename procedure inter-row hoeing to inter_row_hoeing
    reversible do |d|
      d.up do
        execute "UPDATE interventions SET procedure_name = 'inter_row_hoeing' WHERE procedure_name = 'inter-row hoeing'"
      end
      d.down do
        execute "UPDATE interventions SET procedure_name = 'inter-row hoeing' WHERE procedure_name = 'inter_row_hoeing'"
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'crop_residues_grinding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'crop_residues_grinding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'detasseling'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'detasseling'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'plantation_unfixing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'plantation_unfixing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'hand_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'hand_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'gas_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'gas_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'steam_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'steam_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'chemical_mechanical_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'chemical_mechanical_weeding'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'trellising'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'trellising'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'pollination'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'pollination'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'cutting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'cutting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'fertilizing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'fertilizing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'mechanical_planting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'mechanical_planting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'sowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'sowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'sowing_with_spraying'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'sowing_with_spraying'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'all_in_one_sowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'all_in_one_sowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'mulching_material'
          FROM interventions
          WHERE (iparam.reference_name = 'plastic'
            AND interventions.procedure_name = 'plant_mulching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plastic'
          FROM interventions
          WHERE (iparam.reference_name = 'mulching_material'
            AND interventions.procedure_name = 'plant_mulching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'tunnel_installation'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'tunnel_installation'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'tunnel_removing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'tunnel_removing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'net_installation'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'net_installation'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'net_removing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'net_removing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'land_parcel'
            AND interventions.procedure_name = 'swathing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'land_parcel'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'swathing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'topkilling'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'topkilling'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'driver'
          FROM interventions
          WHERE (iparam.reference_name = 'forager_driver'
            AND interventions.procedure_name = 'direct_silage'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'forager_driver'
          FROM interventions
          WHERE (iparam.reference_name = 'driver'
            AND interventions.procedure_name = 'direct_silage'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'driver'
          FROM interventions
          WHERE (iparam.reference_name = 'forager_driver'
            AND interventions.procedure_name = 'plant_mowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'forager_driver'
          FROM interventions
          WHERE (iparam.reference_name = 'driver'
            AND interventions.procedure_name = 'plant_mowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'driver'
          FROM interventions
          WHERE (iparam.reference_name = 'baler_driver'
            AND interventions.procedure_name = 'straw_bunching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'baler_driver'
          FROM interventions
          WHERE (iparam.reference_name = 'driver'
            AND interventions.procedure_name = 'straw_bunching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'plant_mowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'plant_mowing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'straw_bunching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'straw_bunching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'lifting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'lifting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'doer'
          FROM interventions
          WHERE (iparam.reference_name = 'implanter_man'
            AND interventions.procedure_name = 'mechanical_planting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'implanter_man'
          FROM interventions
          WHERE (iparam.reference_name = 'doer'
            AND interventions.procedure_name = 'mechanical_planting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'harvesting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'harvesting'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'cultivation'
          FROM interventions
          WHERE (iparam.reference_name = 'plant'
            AND interventions.procedure_name = 'straw_bunching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'plant'
          FROM interventions
          WHERE (iparam.reference_name = 'cultivation'
            AND interventions.procedure_name = 'straw_bunching'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
