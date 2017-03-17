class AddUseBankGuarantee < ActiveRecord::Migration
  def change
    add_column :loans, :use_bank_guarantee, :boolean
  end
end
