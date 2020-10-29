class AddStateToFinancialYears < ActiveRecord::Migration
  def change
    add_column :financial_years, :state, :string
    reversible do |d|
      d.up do
        execute <<-SQL
          UPDATE financial_years
          SET state = 'opened'
        SQL

        execute <<-SQL
          UPDATE financial_years
          SET state = 'closed'
          WHERE closed = '1'
        SQL
      end
    end
  end
end
