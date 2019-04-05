class FixedAssetBookkeeper < Ekylibre::Bookkeeper
  def call
    @label = tc(:bookkeep_in_use_assets, resource: FixedAsset.model_name.human, number: number, name: name)
    @waiting_asset_account = Account.find_or_import_from_nomenclature(:outstanding_assets)
    @fixed_assets_suppliers_account = Account.find_or_import_from_nomenclature(:fixed_assets_suppliers)
    @fixed_assets_values_account = Account.find_or_import_from_nomenclature(:fixed_assets_values)
    @exceptionnal_depreciations_inputations_expenses_account = Account.find_or_import_from_nomenclature(:exceptional_depreciations_inputations_expenses)

    # fixed asset link to purchase item
    if purchase_items.any? && in_use?
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

    def bookkeep_purchase_item_link
      # puts "with purchase".inspect.red
      journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
        amount = []
        purchase_items.each do |p_item|
          # TODO: get entry item concerning
          jei = JournalEntryItem.where(resource_id: p_item.id, resource_type: p_item.class.name, account_id: @waiting_asset_account.id).first
          next unless jei && jei.real_balance.nonzero?
          entry.add_credit(@label, jei.account.id, jei.real_balance)
          amount << jei.real_balance
        end
        entry.add_debit(@label, asset_account.id, amount.compact.sum, resource: resource, as: :fixed_asset)
      end
    end

    def bookkeep_in_use
      if FinancialYear.at(started_on)&.opened?
        # puts "without purchase".inspect.green
        journal_entry(journal, printed_on: started_on, if: (in_use? && asset_account)) do |entry|
          entry.add_credit(@label, @fixed_assets_suppliers_account.id, depreciable_amount)
          entry.add_debit(@label, asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
        end
      else
        current_fy = FinancialYear.opened.first

        if current_fy && started_on < current_fy.started_on
          # This is a FixedAsset import
          waiting_account = Account.find_or_import_from_nomenclature(:suspense)

          journal_entry(journal, printed_on: current_fy.started_on, if: (in_use? && asset_account)) do |entry|
            entry.add_credit @label, waiting_account.id, depreciable_amount
            entry.add_debit @label, asset_account.id, depreciable_amount
          end
        end
      end
    end

    def bookkeep_scrapped_sold
      out_on = sold_on
      out_on ||= scrapped_on

      # get last depreciation for date out_on
      depreciation_out_on = current_depreciation(out_on)

      if depreciation_out_on

        # check if depreciation have journal_entry
        if depreciation_out_on.journal_entry
          raise StandardError, "This fixed asset depreciation is already bookkeep ( Entry : #{depreciation_out_on.journal_entry.number})"
        end

        next_depreciations = depreciations.where('position > ?', depreciation_out_on.position)

        # check if next depreciations have journal_entry
        if next_depreciations.any?(&:journal_entry)
          raise StandardError, "The next fixed assets depreciations are already bookkeep ( Entry : #{d.journal_entry.number})"
        end

        # stop bookkeeping next depreciations
        next_depreciations.update_all(accountable: false, locked: true)

        # use amount to last bookkeep (net_book_value == current_depreciation.depreciable_amount)
        # use amount to last bookkeep (already_depreciated_value == current_depreciation.depreciated_amount)

        # compute part time

        first_period = out_on.day
        global_period = (depreciation_out_on.stopped_on - depreciation_out_on.started_on) + 1
        first_ratio = (first_period.to_f / global_period.to_f) if global_period
        # second_ratio = (1 - first_ratio)

        first_depreciation_amount_ratio = (depreciation_out_on.amount * first_ratio).round(2)
        # second_depreciation_amount_ratio = (depreciation_out_on.amount * second_ratio).round(2)

        # update current_depreciation with new value and bookkeep it
        depreciation_out_on.stopped_on = out_on
        depreciation_out_on.amount = first_depreciation_amount_ratio
        depreciation_out_on.accountable = true
        depreciation_out_on.save!

        scrapped_value = depreciation_out_on.depreciable_amount
        scrapped_unvalue = depreciation_out_on.depreciated_amount

        # fixed asset sold
        @label = tc(:bookkeep_in_sold_assets, resource: resource.class.model_name.human, number: number, name: name)
        journal_entry(journal, printed_on: sold_on, as: :sold, if: sold?) do |entry|
          entry.add_credit(@label, asset_account.id, depreciable_amount, resource: resource, as: :fixed_asset)
          entry.add_debit(@label, @fixed_assets_values_account.id, scrapped_value)
          entry.add_debit(@label, allocation_account.id, scrapped_unvalue)
        end

        # fixed asset scrapped
        label_1 = tc(:bookkeep_exceptionnal_scrapped_assets, resource: resource.class.model_name.human, number: number, name: name)
        label_2 = tc(:bookkeep_exit_assets, resource: resource.class.model_name.human, number: number, name: name)

        journal_entry(journal, printed_on: scrapped_on, as: :scrapped, if: scrapped?) do |entry|
          entry.add_debit(label_1, @exceptionnal_depreciations_inputations_expenses_account.id, scrapped_value)
          entry.add_credit(label_1, allocation_account.id, scrapped_value)
          entry.add_debit(label_2, allocation_account.id, scrapped_value)
          entry.add_credit(label_2, asset_account.id, scrapped_value, resource: resource, as: :fixed_asset)
        end
      end
    end

end