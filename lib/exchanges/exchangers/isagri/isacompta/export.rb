# -*- coding: utf-8 -*-
# To import files COFTW.isa
Exchanges.add_importer(:isagri_isacompta_export) do |file, w|
  default_journal_natures = {
    "ac" => :purchases,
    "ve" => :sales,
    "tr" => :bank,
    # "tr" => :cash,
    "an" => :forward
  }

  version = nil
  begin
    File.open(file, "rb:CP1252") do |f|
      version = f.readline.to_s[13..16].to_i
    end
  rescue
    raise NotWellFormedFileError
  end
  used_versions = [8550]
  version = used_versions.select{|x| x <= version}.sort[-1]

  if version == 8550
    isa = SVF::Isa8550.parse(file)

    if isa_fy = isa.folder.financial_year
      # Find or create financial year
      unless fy = FinancialYear.find_by_started_on_and_stopped_on(isa_fy.started_on, isa_fy.stopped_on)
        if FinancialYear.where("? BETWEEN started_on AND stopped_on OR ? BETWEEN started_on AND stopped_on", isa_fy.started_on, isa_fy.stopped_on).count > 0
          raise Exchanges::IncompatibleDataError.new("Financial year dates overlaps existing financial years")
        else
          raise Exchanges::IncompatibleDataError.new("Accountancy must be in Euro (EUR) not in '#{isa_fy.currency}'") if isa_fy.currency != "EUR"
          fy = FinancialYear.create!(started_on: isa_fy.started_on, stopped_on: isa_fy.stopped_on)
        end
      end

      w.count isa_fy.accounts.count + isa_fy.journals.count + isa_fy.entries.count

      # Ignore Analytics data

      # Adds missing accounts
      all_accounts = {}
      for isa_account in isa_fy.accounts
        unless account = Account.find_by_number(isa_account.number)
          account = Account.create!(:name => (isa_account.label.blank? ? isa_account.number : isa_account.label), :number => isa_account.number, :reconcilable => isa_account.reconcilable, :last_letter => isa_account.letter, :is_debit => (isa_account.input_direction=='de' ? true : false), :comment => isa_account.to_s)
        end
        all_accounts[isa_account.number] = account.id
        w.check_point
      end

      # Ignore taxes

      # Add journals
      # Find used journals
      used_journals = isa_fy.entries.collect{|e| e.journal}.uniq
      all_journals = {}
      for isa_journal in isa_fy.journals
        if used_journals.include?(j.code)
          journal = nil
          journals = Journal.find_all_by_code(isa_journal.code)
          journal = journals[0] if journals.size == 1
          unless journal
            journals = Journal.where("LOWER(name) LIKE ? ", isa_journal.label.mb_chars.downcase)
            journal = journals[0] if journals.size == 1
          end
          unless journal
            journals = Journal.where("TRANSLATE(LOWER(name), 'àâäéèêëìîïòôöùûüỳŷÿ', 'aaaeeeeiiiooouuuyyy') LIKE ? ", '%'+isa_journal.label.mb_chars.downcase.gsub(/\s+/, '%')+'%')
            journal = journals[0] if journals.size == 1
          end
          journal ||= Journal.create!(:code => isa_journal.code, :name => (isa_journal.label.blank? ? "[#{isa_journal.code}]" : isa_journal.label), :nature => default_journal_natures[isa_journal.type]||:various) # , :closed_on => isa_journal.last_close_on
          all_journals[isa_journal.code] = journal.id
        end
        w.check_point
      end

      entries_to_import = isa_fy.entries
      total_count = entries_to_import.size
      unused_entries = fy.journal_entries.collect{|je| je.id}.uniq.sort
      status, start, count, interval = "", Time.now, 0, 1.00
      next_start = start+interval

      # Determine which search filter is the best
      # filters = {}
      # filters[:number] = entries_to_import.collect{|e| e.number}
      # filters[:code] = entries_to_import.collect{|e| "#{e.code}"}
      # filters[:journal_and_code] = entries_to_import.collect{|e| "#{e.journal}-#{e.code}"}
      # for k, v in filters
      #   if v.uniq.sort == v.sort
      #     puts "Filter #{k} works"
      #   else
      #     puts "Filter #{k} cannot work!"
      #   end
      # end
      # raise "Stop"

      for isa_entry in entries_to_import
        w.check_point
        entry, journal_id = nil, all_journals[isa_entry.journal]
        unless isa_entry.number.blank?
          entries = JournalEntry.where("journal_id=? AND printed_on=? AND number = ?", journal_id, isa_entry.printed_on, isa_entry.number)
          if entries.size == 1
            entry = entries.first
          else
            entries = JournalEntry.where("journal_id=? AND printed_on=? AND SUBSTR(number,1,2)||SUBSTR(number,LENGTH(number)-5,6) = ?", journal_id, isa_entry.printed_on, isa_entry.number)
            entry = entries.first if entries.size == 1
          end
        end
        unless entry
          number = "#{isa_entry.journal}#{isa_entry.code.to_s.rjust(6,'0')}"
          entries = JournalEntry.find_all_by_number_and_journal_id_and_printed_on(number, journal_id, isa_entry.printed_on)
          if entries.size == 1
            entry = entries.first
          elsif entries.size > 1
            number += rand.to_s[2..-1].to_i.to_s(36).upcase
            number = number[0..255]
          end
          unless entry
            entry = JournalEntry.create(:number => number, :journal_id => all_journals[isa_entry.journal], :printed_on => isa_entry.printed_on, :created_on => isa_entry.created_on, :updated_at => isa_entry.updated_on, :lock_version => isa_entry.version_number)  # , :state => (isa_entry.unupdateable? ? :confirmed : :draft)
            raise isa_entry.inspect+"\n"+entry.errors.full_messages.to_sentence unless entry.valid?
          end
        end

        unused_entries.delete(entry.id)

        entry.lines.clear
        for isa_line in isa_entry.lines
          if isa_line.debit < 0 or isa_line.credit < 0
            debit = isa_line.debit
            isa_line.debit = isa_line.credit.abs
            isa_line.credit = debit.abs
          end
          line =  entry.lines.create(:account_id => all_accounts[isa_line.account], :name => "#{isa_line.label} (#{isa_entry.label})", :real_debit => isa_line.debit, :real_credit => isa_line.credit, :letter => (isa_line.lettering > 0 ? isa_line.letter : nil), :comment => isa_line.to_s)
          raise isa_line.to_s+"\n"+line.errors.full_messages.to_sentence unless line.valid?
        end

        count += 1
        if Time.now > next_start
          status = print_jauge(count, total_count, :replace => status, :start => start)
          next_start = Time.now + interval
        end
      end



      if unused_entries.any?
        puts "#{unused_entries.size} destroyed entries (on #{total_count})"
        JournalEntry.destroy(unused_entries)
      end

      # Check all lines line-per-line
      found, expected = fy.journal_entries.size, isa_fy.entries.size
      raise StandardError.new("The count of entries is different: #{found} in database and #{expected} in file") if found != expected
      found, expected = JournalEntryLine.between(fy.started_on, fy.stopped_on).count, isa_fy.entries.inject(0){|s, e| s += e.lines.size}
      raise StandardError.new("The count of entry lines is different: #{found} in database and #{expected} in file") if found != expected
      for entry in fy.journal_entries
      end

    end

  else
    raise Exchanges::NotWellFormedFileError, "Version does not seems to be supported"
  end

end
