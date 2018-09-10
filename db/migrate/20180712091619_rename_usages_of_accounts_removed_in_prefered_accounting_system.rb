class RenameUsagesOfAccountsRemovedInPreferedAccountingSystem < ActiveRecord::Migration
  ACCOUNTS = [
    { name: 'long_time_animal_stock', fr_pcga: '31', fr_pcg82: 'NONE' },
    { name: 'raw_material_and_supplies', fr_pcga: 'NONE', fr_pcg82: '31' },
    { name: 'short_time_animal_stock', fr_pcga: '32', fr_pcg82: 'NONE' },
    { name: 'other_supplies', fr_pcga: 'NONE', fr_pcg82: '32' },
    { name: 'long_cycle_vegetals_stock', fr_pcga: '33', fr_pcg82: 'NONE' },
    { name: 'in_cycle_products_stock', fr_pcga: 'NONE', fr_pcg82: '33' },
    { name: 'short_cycle_vegetals_stock', fr_pcga: '34', fr_pcg82: 'NONE' },
    { name: 'in_cycle_services_stock', fr_pcga: 'NONE', fr_pcg82: '34' },
    { name: 'long_cycle_products_stock', fr_pcga: '35', fr_pcg82: 'NONE' },
    { name: 'products_stock', fr_pcga: 'NONE', fr_pcg82: '35' },
    { name: 'short_cycle_products_stock', fr_pcga: '36', fr_pcg82: 'NONE' },
    { name: 'assets_products_stock', fr_pcga: 'NONE', fr_pcg82: '36' },
    { name: 'end_products_stock', fr_pcga: '37', fr_pcg82: 'NONE' },
    { name: 'merchandising_products_stock', fr_pcga: 'NONE', fr_pcg82: '37' },
    { name: 'social_security', fr_pcga: '431', fr_pcg82: 'NONE' },
    { name: 'social_agricultural_mutuality', fr_pcga: 'NONE', fr_pcg82: '431' },
    { name: 'making_services_expenses', fr_pcga: '605', fr_pcg82: 'NONE' },
    { name: 'equipment_expenses', fr_pcga: 'NONE', fr_pcg82: '605' },
    { name: 'bonus_staff_expenses', fr_pcga: '6413', fr_pcg82: 'NONE' },
    { name: 'associates_salary', fr_pcga: 'NONE', fr_pcg82: '6413' }
  ].freeze
  def change
    reversible do |d|
      d.up do
        accounting_systems = %i[fr_pcg82 fr_pcga]
        current_accounting_system = preferred_accounting_system
        accounts_to_update = ACCOUNTS.select { |account| account[current_accounting_system] == 'NONE' }.compact
        accounts_to_update.each do |account|
          other_accounting_system = (accounting_systems - [current_accounting_system]).first
          new_usage = ACCOUNTS.find { |a| a[current_accounting_system] == account[other_accounting_system] }[:name]
          execute <<-SQL
            UPDATE accounts
            SET usages = '#{new_usage}'
            WHERE usages = '#{account[:name]}'
          SQL
        end
      end

      d.down do
        # NOOP
      end
    end
  end

  private

  def preferred_accounting_system
    accounting_system = execute(<<-SQL).first
      SELECT  "preferences".string_value FROM "preferences" WHERE "preferences"."name" = 'accounting_system' LIMIT 1
    SQL
    return :fr_pcg82 unless accounting_system

    accounting_system['string_value'].to_sym
  end
end
