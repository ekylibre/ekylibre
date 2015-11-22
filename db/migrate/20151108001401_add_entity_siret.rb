class AddSiretAndShapeSupports < ActiveRecord::Migration
  def change
    rename_column :entities, :siren, :siret
    reversible do |d|
      d.up do
        # TODO Use a PL/PgSQL function to speed up migration
        select_values("SELECT DISTINCT siret FROM entities").each do |siren|
          cb = Luhn.control_digit(siren)
          execute "UPDATE entities SET siret = '#{siren}0001#{cb}' WHERE siret = '#{siren}'"
        end
      end
      d.down do
        execute "UPDATE entities SET siret = LEFT(siret, 9)"
      end
    end
  end
end
