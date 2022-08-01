# frozen_string_literal: true

module FEC
  module Datasource
    class Exporter < FEC::Datasource::Base

      # Return hash of datas which can be used by both XML and Text/CSV exporters
      def perform
        datasource = {}
        datasource[:date_cloture] = @financial_year.stopped_on.strftime('%Y-%m-%d')
        datasource[:journals] = []

        # data request
        forward_journals = @journals.where(nature: 'forward')
        forward_entries = JournalEntry.where.not(state: 'draft').where(journal_id: forward_journals.pluck(:id)).between(@started_on, @stopped_on)
        if forward_journals && forward_entries.any?
          if forward_entries.pluck(:continuous_number).compact.uniq.count > 1
            forward_entries = forward_entries.reorder(:continuous_number)
          end

          # for a new report accountancy data
          forward_journal_data = {}
          forward_journal_data[:code] = forward_journals.first.code
          forward_journal_data[:name] = forward_journals.first.name
          forward_journal_data[:entries] = []
          # put all items in forward journal in the same entry to match mandatory
          # reference to last items of forward items
          forward_entry_data = {}
          forward_entry_data[:continuous_number] = forward_entries.last&.continuous_number || ''
          forward_entry_data[:printed_on] = forward_entries.last&.printed_on
          forward_entry_data[:libelle] = "BO"
          forward_entry_data[:number] = forward_entries.last&.number
          forward_entry_data[:date] = forward_entries.last&.printed_on
          forward_entry_data[:letter] = nil
          forward_entry_data[:lettered_at] = nil
          forward_entry_data[:validated_at] = forward_entries.last&.validated_at
          forward_entry_data[:items] = []

          forward_entry_ids = forward_entries.pluck(:id)

          JournalEntryItem.where(entry_id: forward_entry_ids).of_unclosure_account_number.includes(:account).where.not(balance: 0.0).reorder('accounts.number').each do |forward_item|
            forward_item_data = {}
            account = forward_item.account
            if account.nature == 'auxiliary'
              forward_item_data[:compte_num] = account.number.chomp(account.auxiliary_number)
              forward_item_data[:compte_lib] = account.centralizing_account_name
              forward_item_data[:compte_aux_num] = account.auxiliary_number
              forward_item_data[:compte_aux_lib] = account.name
            else
              forward_item_data[:compte_num] = account.number
              forward_item_data[:compte_lib] = account.name
              forward_item_data[:compte_aux_num] = nil
              forward_item_data[:compte_aux_lib] = nil
            end
            forward_item_data[:montant_devise] = nil
            forward_item_data[:i_devise] = nil
            forward_item_data[:debit] = format('%5.2f', forward_item.debit)
            forward_item_data[:credit] = format('%5.2f', forward_item.credit)
            forward_entry_data[:items] << forward_item_data
          end

          forward_journal_data[:entries] << forward_entry_data
          datasource[:journals] << forward_journal_data
        end

        # for main accountancy data
        journals = @journals.where.not(nature: %w[closure forward result])
        journals.each do |journal|
          entries = journal.entries.where.not(state: 'draft').between(@started_on, @stopped_on)
          next if entries.empty?

          if entries.pluck(:continuous_number).compact.uniq.count > 1
            entries = entries.reorder(:continuous_number)
          end

          journal_data = {}
          journal_data[:code] = journal.code
          journal_data[:name] = journal.name
          journal_data[:entries] = []
          entries.includes(:incoming_payments, :purchase_payments, items: :account).references(items: :account).each do |entry|
            items = entry.items.of_unclosure_account_number.includes(:account).where.not(balance: 0.0)
            next if items.empty?

            next if %w[ba_ir_cash_accountancy bnc_ir_cash_accountancy].include?(@fiscal_position) && !entry.first_payment

            entry_data = {}
            entry_data[:continuous_number] = (entry.continuous_number.present? ? entry.continuous_number : '')
            entry_data[:printed_on] = entry.printed_on
            entry_data[:libelle] = remove_unwanted_caracters(entry.name) if entry.name.present?
            entry_data[:number] = entry.number
            entry_data[:date] = entry.printed_on
            entry_data[:letter] = entry.complete_letter
            entry_data[:lettered_at] = entry.lettered_at
            entry_data[:validated_at] = entry.validated_at
            if %w[ba_ir_cash_accountancy bnc_ir_cash_accountancy].include?(@fiscal_position)
              entry_data[:date_rglt] = entry.first_payment.paid_at
              entry_data[:mode_rglt] = entry.first_payment.mode.name
              entry_data[:nat_op] = nil
            end
            if @fiscal_position == 'bnc_ir_cash_accountancy'
              entry_data[:id_client] = entry.resource.third.full_name
            end
            # resource = Maybe(entry.resource)
            # if resource.is_some? && @fiscal_position == 'bnc_ir_cash_accountancy'
            # if resource.has_attribute?(:client_id).get && resource.client.get
            # entry_data[:id_client] = resource.client.get.number
            # elsif resource.has_attribute?(:supplier_id).get && resource.supplier.get
            # entry_data[:id_client] = resource.supplier.get.full_name
            # end
            # end
            entry_data[:items] = []
            items.each do |item|
              entry_item_data = {}
              account = item.account
              if account.nature == 'auxiliary'
                entry_item_data[:compte_num] = account.number.chomp(account.auxiliary_number)
                entry_item_data[:compte_lib] = account.centralizing_account_name
                entry_item_data[:compte_aux_num] = account.auxiliary_number
                entry_item_data[:compte_aux_lib] = account.name
              else
                entry_item_data[:compte_num] = account.number
                entry_item_data[:compte_lib] = account.name
                entry_item_data[:compte_aux_num] = nil
                entry_item_data[:compte_aux_lib] = nil
              end
              entry_item_data[:montant_devise] = nil
              entry_item_data[:i_devise] = nil
              entry_item_data[:debit] = format('%5.2f', item.debit)
              entry_item_data[:credit] = format('%5.2f', item.credit)
              entry_data[:items] << entry_item_data
            end
            journal_data[:entries] << entry_data
          end
          datasource[:journals] << journal_data
        end
        datasource
      end

      private def remove_unwanted_caracters(field)
        field
          .gsub(/(;|"|\?|<|>|\=|\*|\^|\$|\~|`|\t|\%|\!|\§|#|@)/, '')
          .gsub(/(&|\|)/, '-')
          .squish
      end
    end
  end
end
