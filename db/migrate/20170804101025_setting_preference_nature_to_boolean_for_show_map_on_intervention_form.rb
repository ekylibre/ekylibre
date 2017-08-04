class SettingPreferenceNatureToBooleanForShowMapOnInterventionForm < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          UPDATE preferences
          SET nature = 'boolean',
              boolean_value = true,
              string_value      = null,
              integer_value     = null,
              decimal_value     = null,
              record_value_id   = null,
              record_value_type = null
          WHERE name = 'show_map_on_intervention_form';
        SQL
      end

      dir.down do
        # NOOP
      end
    end
  end
end
