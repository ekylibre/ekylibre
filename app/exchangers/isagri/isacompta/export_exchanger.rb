module Isagri
  module Isacompta
    # Exchanger to import COFTW.isa files from IsaCompta software
    class ExportExchanger < ActiveExchanger::Base
      def check
        SVF::Isacompta8550.parse(file)
      rescue SVF::InvalidSyntax
        return false
      end

      def import
        default_journal_natures = {
          'ac' => :purchases,
          've' => :sales,
          'tr' => :bank,
          'an' => :forward
        }

        version = nil
        begin
          File.open(file, 'rb:CP1252') do |f|
            version = f.readline.to_s[13..16].to_i
          end
        rescue
          raise ActiveExchanger::NotWellFormedFileError
        end
        used_versions = [8550]
        version = used_versions.select { |x| x <= version }.sort[-1]

        if version == 8550
          begin
            isa = SVF::Isacompta8550.parse(file)
          rescue SVF::InvalidSyntax
            raise ActiveExchanger::NotWellFormedFileError
          end

          raise ActiveExchanger::NotWellFormedFileError unless isa.folder.financial_year

          isa_fy = isa.folder.financial_year
          # Find or create financial year
          fy = FinancialYear.find_by(started_on: isa_fy.started_on, stopped_on: isa_fy.stopped_on)
          unless fy
            if FinancialYear.where('? BETWEEN started_on AND stopped_on OR ? BETWEEN started_on AND stopped_on', isa_fy.started_on, isa_fy.stopped_on).any?
              raise ActiveExchanger::IncompatibleDataError, 'Financial year dates overlaps existing financial years'
            else
              if isa_fy.currency != 'EUR'
                raise ActiveExchanger::IncompatibleDataError, "Accountancy must be in Euro (EUR) not in '#{isa_fy.currency}'"
              end
              fy = FinancialYear.create!(started_on: isa_fy.started_on, stopped_on: isa_fy.stopped_on)
            end

            w.count = isa_fy.accounts.count + isa_fy.journals.count + isa_fy.entries.count

            # Ignore Analytics data

            # Adds missing accounts
            all_accounts = {}
            isa_fy.accounts.each do |isa_account|
              unless account = Account.find_by(number: isa_account.number)
                account = Account.create!(name: (isa_account.label.blank? ? isa_account.number : isa_account.label), number: isa_account.number, reconcilable: isa_account.reconcilable, last_letter: isa_account.letter, debtor: (isa_account.input_direction == 'de'), description: isa_account.to_s)
              end
              all_accounts[isa_account.number] = account.id
              w.check_point
            end

            # Ignore taxes
            # TODO Take in account taxes data from Isacompta Export format

            # Add journals
            # Find used journals
            used_journals = isa_fy.entries.collect(&:journal).uniq
            all_journals = {}
            isa_fy.journals.each do |isa_journal|
              if used_journals.include?(isa_journal.code)
                journal = nil
                journals = Journal.where(code: isa_journal.code)
                journal = journals[0] if journals.size == 1
                unless journal
                  journals = Journal.where('LOWER(name) LIKE ? ', isa_journal.label.mb_chars.downcase)
                  journal = journals[0] if journals.size == 1
                end
                unless journal
                  journals = Journal.where("TRANSLATE(LOWER(name), 'àâäéèêëìîïòôöùûüỳŷÿ', 'aaaeeeeiiiooouuuyyy') LIKE ? ", '%' + isa_journal.label.mb_chars.downcase.gsub(/\s+/, '%') + '%')
                  journal = journals[0] if journals.size == 1
                end
                journal ||= Journal.create!(code: isa_journal.code, name: (isa_journal.label.blank? ? "[#{isa_journal.code}]" : isa_journal.label), nature: default_journal_natures[isa_journal.type] || :various) # , :closed_on => isa_journal.last_close_on
                all_journals[isa_journal.code] = journal.id
              end
              w.check_point
            end

            entries_to_import = isa_fy.entries
            total_count = entries_to_import.size
            unused_entries = fy.journal_entries.collect(&:id).uniq.sort

            # Determine which search filter is the best
            # filters = {}
            # filters[:number] = entries_to_import.collect{|e| e.number}
            # filters[:code] = entries_to_import.collect{|e| "#{e.code}"}
            # filters[:journal_and_code] = entries_to_import.collect{|e| "#{e.journal}-#{e.code}"}
            # filters.each do |k, v|
            #   if v.uniq.sort == v.sort
            #     w.debug "Filter #{k} works"
            #   else
            #     w.debug "Filter #{k} cannot work!"
            #   end
            # end
            # raise "Stop"

            entries_to_import.each do |isa_entry|
              w.check_point
              entry = nil
              journal_id = all_journals[isa_entry.journal]
              if isa_entry.number.present?
                entries = JournalEntry.where(journal_id: journal_id, printed_on: isa_entry.printed_on, number: isa_entry.number)
                if entries.size == 1
                  entry = entries.first
                else
                  entries = JournalEntry.where(journal_id: journal_id, printed_on: isa_entry.printed_on).where('SUBSTR(number,1,2)||SUBSTR(number,LENGTH(number)-5,6) = ?', isa_entry.number)
                  entry = entries.first if entries.size == 1
                end
              end
              unless entry
                number = "#{isa_entry.journal}#{isa_entry.code.to_s.rjust(6, '0')}"
                entries = JournalEntry.where(number: number, journal_id: journal_id, printed_on: isa_entry.printed_on)
                if entries.size == 1
                  entry = entries.first
                elsif entries.size > 1
                  number += rand.to_s[2..-1].to_i.to_s(36).upcase
                  number = number[0..255]
                end
                entry ||= JournalEntry.new(
                  number: number,
                  journal_id: all_journals[isa_entry.journal],
                  printed_on: isa_entry.printed_on,
                  created_at: isa_entry.created_on,
                  updated_at: isa_entry.updated_on,
                  lock_version: isa_entry.version_number,
                  # state: (isa_entry.unupdateable? ? :confirmed : :draft),
                  items: []
                )
              end

              unused_entries.delete(entry.id)

              isa_entry.lines.each do |isa_line|
                if isa_line.debit < 0 || isa_line.credit < 0
                  debit = isa_line.debit
                  isa_line.debit = isa_line.credit.abs
                  isa_line.credit = debit.abs
                end
                entry.items << JournalEntryItem.new(
                  account_id: all_accounts[isa_line.account],
                  name: "#{isa_line.label} (#{isa_entry.label})",
                  real_debit: isa_line.debit,
                  real_credit: isa_line.credit,
                  letter: (isa_line.lettering > 0 ? isa_line.letter : nil),
                  description: isa_line.to_s
                )
              end

              entry.save
              raise isa_entry.inspect + "\n" + entry.errors.full_messages.to_sentence unless entry.valid?
            end

            if unused_entries.any?
              w.warn "#{unused_entries.size} destroyed entries (on #{total_count})"
              JournalEntry.destroy(unused_entries)
            end

            # Check all items item-per-item
            found = fy.journal_entries.size
            expected = isa_fy.entries.size
            if found != expected
              raise StandardError, "The count of entries is different: #{found} in database and #{expected} in file"
            end
            found = JournalEntryItem.between(fy.started_on, fy.stopped_on).count
            expected = isa_fy.entries.inject(0) { |s, e| s += e.lines.size }
            if found != expected
              raise StandardError, "The count of entry items is different: #{found} in database and #{expected} in file"
            end
            # fy.journal_entries.each do |entry|
            # end

          end

        else
          raise ActiveExchanger::NotWellFormedFileError, 'Version does not seems to be supported'
        end

        true
      end
    end
  end
end
