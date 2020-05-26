class FixedAssetBookkeeper < Ekylibre::Bookkeeper
  def call
    @label = tc(:bookkeep_in_use_assets, resource: FixedAsset.model_name.human, number: number, name: name)
    @generic_waiting_asset_account = Account.find_or_import_from_nomenclature(:outstanding_assets)
    @fixed_assets_suppliers_account = Account.find_or_import_from_nomenclature(:fixed_assets_suppliers)
    @fixed_assets_values_account = Account.find_or_import_from_nomenclature(:fixed_assets_values)
    @exceptionnal_depreciations_inputations_expenses_account = Account.find_or_import_from_nomenclature(:exceptional_depreciations_inputations_expenses)

    if !purchase_items.any? && waiting?
      bookkeep_waiting

    elsif purchase_items.any? && waiting? && waiting_asset_account
      bookkeep_waiting_asset_account_switch

    # fixed asset link to purchase item
    elsif purchase_items.any? && in_use?
      bookkeep_purchase_item_link

      # fixed asset link to nothing
    elsif in_use?
      bookkeep_in_use

      # fixed asset sold or scrapped
    elsif (sold? && !sold_journal_entry) || (scrapped? && !scrapped_journal_entry)
      bookkeep_scrapped_sold
    end
  end

  private

    def bookkeep_waiting
      @label = tc(:bookkeep_waiting_assets, resource: resource.class.model_name.human, number: number, name: name)
      journal_entry(journal, printed_on: waiting_on, as: :waiting, if: waiting?) do |entry|
        credit_account = special_imputation_asset_account || @fixed_assets_suppliers_account
        debit_account = waiting_asset_account || @generic_waiting_asset_account
        entry.add_credit(@label, credit_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
        entry.add_debit(@label, debit_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
      end
    end

    def bookkeep_waiting_asset_account_switch
      @label = tc(:bookkeep_waiting_assets, resource: resource.class.model_name.human, number: number, name: name)
      journal_entry(journal, printed_on: waiting_on, as: :waiting, if: waiting?) do |entry|
        amounts = []
        purchase_items.each do |purchase_item|
          entry_item = purchase_item.journal_entry.items.detect { |i| i.resource_id == purchase_item.id && i.resource_prism == 'item_product' }
          next if waiting_asset_account_id == entry_item.account.id
          entry.add_credit(@label, entry_item.account.id, entry_item.real_balance, resource: resource, as: :fixed_asset)
          amounts << entry_item.real_balance
        end
        entry.add_debit(@label, waiting_asset_account_id, amounts.compact.sum, resource: resource, as: :fixed_asset) unless amounts.empty?
      end
    end

    def bookkeep_purchase_item_link
      # puts "with purchase".inspect.red
      journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
        amount = []
        purchase_items.each do |p_item|
          # TODO: get entry item concerning
          jei = JournalEntryItem.find_by(resource_id: p_item.id, resource_type: p_item.class.name, account_id: @generic_waiting_asset_account.id)
          next unless jei && jei.real_balance.nonzero?
          account = if attribute_was(:state) == 'waiting' && waiting_asset_account
                      waiting_asset_account
                    else
                      jei.account
                    end
          entry.add_credit(@label, account.id, jei.real_balance, resource: resource, as: :fixed_asset)
          amount << jei.real_balance
        end
        entry.add_debit(@label, asset_account.id, amount.compact.sum, resource: resource, as: :fixed_asset)
      end
    end

    def bookkeep_in_use
      if FinancialYear.at(started_on)&.opened?
        # puts "without purchase".inspect.green
        if waiting_journal_entry
          waiting_account_id = waiting_asset_account_id ? waiting_asset_account_id : @generic_waiting_asset_account.id
          journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
            entry.add_credit(@label, waiting_account_id, depreciable_amount, resource: resource, as: :fixed_asset)
            entry.add_debit(@label, asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
          end
        elsif special_imputation_asset_account
          journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
            entry.add_credit(@label, special_imputation_asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
            entry.add_debit(@label, asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
          end
        else
          journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
            entry.add_credit(@label, @fixed_assets_suppliers_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
            entry.add_debit(@label, asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
          end
        end
      else
        current_fy = FinancialYear.opened.first

        if current_fy && started_on < current_fy.started_on
          # This is a FixedAsset import
          generic_waiting_account = Account.find_or_import_from_nomenclature(:suspense)

          journal_entry(journal, printed_on: current_fy.started_on, if: (in_use? && asset_account)) do |entry|
            entry.add_credit @label, generic_waiting_account.id, depreciable_amount, resource: resource, as: :fixed_asset
            entry.add_debit @label, asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset
          end
        end
      end
    end

    def bookkeep_scrapped_sold
      out_on = sold_on
      out_on ||= scrapped_on

      # set correct label for entry
      if sold?
       label = :bookkeep_in_sold_assets
      elsif scrapped?
       label = :bookkeep_exit_assets
      end

      # get last depreciation for date out_on
      depreciation_out_on = current_depreciation(out_on)

      if depreciation_out_on
        depreciation_value = depreciation_out_on.depreciable_amount
        depreciation_unvalue = depreciation_out_on.depreciated_amount

        # fixed asset go out (sold or scrapped)
        @label = tc(label, resource: resource.class.model_name.human, number: number, name: name)
        journal_entry(journal, printed_on: out_on, as: self.state.to_sym) do |entry|
          entry.add_credit(@label, asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
          entry.add_debit(@label, @fixed_assets_values_account.id, depreciation_value, resource: resource, as: :fixed_asset)
          entry.add_debit(@label, allocation_account.id, depreciation_unvalue, resource: resource, as: :fixed_asset)
        end
      end
    end
end
