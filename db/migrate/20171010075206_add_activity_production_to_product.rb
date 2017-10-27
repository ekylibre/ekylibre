class AddActivityProductionToProduct < ActiveRecord::Migration
  def change
    add_reference :products, :activity_production, index: true, foreign_key: true

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          UPDATE products AS p
          SET activity_production_id = td.activity_production_id
          FROM target_distributions AS td
          WHERE p.id = td.target_id
            AND td.stopped_at IS NULL
        SQL
      end

      dir.down do
        # NOOP
      end
    end
  end
end
