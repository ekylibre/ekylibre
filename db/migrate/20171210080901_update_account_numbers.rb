class UpdateAccountNumbers < ActiveRecord::Migration
  def up
    execute "UPDATE accounts SET number = RPAD(number, 8, '0') WHERE LENGTH(number) < 8"
  end

  def down
    # NOOP
  end
end
