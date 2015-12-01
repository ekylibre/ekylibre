class AddEntitySiret < ActiveRecord::Migration
  def change
    rename_column :entities, :siren, :siret_number
    reversible do |d|
      d.up do
        # TODO: Use a PL/PgSQL function to speed up migration
        select_values('SELECT DISTINCT siret_number FROM entities WHERE LENGTH(TRIM(siret_number)) = 9').each do |siren|
          cb = Luhn.control_digit(siren.to_s + '0001').to_s
          execute "UPDATE entities SET siret_number = '#{siren}0001#{cb}' WHERE siret_number = '#{siren}'"
        end
      end
      d.down do
        execute 'UPDATE entities SET siret_number = LEFT(siret_number, 9)'
      end
    end
  end
end
