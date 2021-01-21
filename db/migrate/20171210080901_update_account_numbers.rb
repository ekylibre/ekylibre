class UpdateAccountNumbers < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE accounts SET number = RPAD(number, 8, '0') WHERE LENGTH(number) < 8"
  end

  def down
    # NOOP
  end
end
