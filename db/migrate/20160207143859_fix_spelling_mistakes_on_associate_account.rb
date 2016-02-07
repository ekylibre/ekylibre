# Migration generated with nomenclature migration #20160207142352
class FixSpellingMistakesOnAssociateAccount < ActiveRecord::Migration
  ACCOUNTS = {
    associated_accounts: :associates_current_accounts,
    locked_associated_accounts: :associates_frozen_accounts,
    principal_associated_accounts: :principal_associates_current_accounts,
    usual_associated_accounts: :usual_associates_current_accounts
  }.freeze

  def change
    reversible do |dir|
      dir.up do
        ACCOUNTS.each do |o, n|
          execute "UPDATE accounts SET usages = NULLIF(TRIM(REPLACE(' ' || COALESCE(usages, '') || ' ', ' #{o} ', ' #{n} ')), '')"
        end
        execute "UPDATE cashes SET nature = 'associate_account' WHERE nature = 'associated_account'"
      end
      dir.down do
        ACCOUNTS.each do |o, n|
          execute "UPDATE accounts SET usages = NULLIF(TRIM(REPLACE(' ' || COALESCE(usages, '') || ' ', ' #{n} ', ' #{o} ')), '')"
        end
        execute "UPDATE cashes SET nature = 'associated_account' WHERE nature = 'associate_account'"
      end
    end
  end
end
