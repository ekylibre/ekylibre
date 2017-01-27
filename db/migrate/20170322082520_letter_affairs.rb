class LetterAffairs < ActiveRecord::Migration
  def up
    Affair.find_each(&:save)
  end

  def down
    raise IrreversibleMigration
  end
end
