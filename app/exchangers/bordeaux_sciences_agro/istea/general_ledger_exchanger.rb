class BordeauxSciencesAgro::ISTEA::GeneralLedgerExchanger < ActiveExchanger::Base
  def check
    blank_string = ''.freeze
    rows = CSV.read(file, encoding: 'CP1252', col_sep: ';')
    valid = true
    w.count = rows.size
    rows.sort! { |a, b| a[13].to_s + a[3].to_s + (a[4] || blank_string) <=> b[13].to_s + b[3].to_s + (b[4] || blank_string) }
    count = 0
    entry = nil
    old = nil
    used_numbers = {}
    accounts = {}
    journals = {}
    entities = {}
    rows.each_with_index do |row, index|
      line_number = index + 2
      prompt = "L#{line_number.to_s.yellow}"
      entry_number = row[4].to_s
      entry_number.gsub!(/[^0-9a-z]/i, '')
      if row[1].to_s
        unless j = Journal.find_by(code: row[1].to_s)
          w.info "Journal #{row[1]} will be created in EUR"
        end
      end
      r = {
        account: accounts[row[0]],
        journal: journals[row[1]],
        page_number: row[2], # What's that ?
        printed_on: Date.parse(row[3]),
        entry_number: entry_number,
        entity_name: row[5],
        entry_name: row[6],
        debit: row[7].to_d,
        credit: row[8].to_d,
        vat: row[9],
        comment: row[10],
        letter: row[11],
        what_on: row[12],
        financial_year_code: row[13]
      }.to_struct
      # w.check_point
    end
    valid
  end

  def import
    blank_string = ''.freeze
    rows = CSV.read(file, encoding: 'CP1252', col_sep: ';')
    rows.collect! do |row|
      row << FinancialYear.at(Date.parse(row[3])).code
    end
    w.count = rows.size
    w_count = (rows.size > 100 ? rows.size / 100 : 100)
    rows.sort! { |a, b| a[13].to_s + a[3].to_s + (a[4] || blank_string) <=> b[13].to_s + b[3].to_s + (b[4] || blank_string) }

    count = 0
    entry = nil
    old = nil
    used_numbers = {}
    accounts = {}
    journals = {}
    entities = {}
    rows.each_with_index do |row, index|
      entry_number = row[4].to_s
      entry_number.gsub!(/[^0-9a-z]/i, '')
      accounts[row[0]] ||= Account.get(row[0])
      journals[row[1].to_s] ||= Journal.create_with(name: "Journal #{row[1]}", currency: 'EUR').find_or_create_by!(code: row[1].to_s)
      r = {
        account: accounts[row[0]],
        journal: journals[row[1]],
        page_number: row[2], # What's that ?
        printed_on: Date.parse(row[3]),
        entry_number: entry_number,
        entity_name: row[5],
        entry_name: row[6],
        debit: row[7].to_d,
        credit: row[8].to_d,
        vat: row[9],
        comment: row[10],
        letter: row[11],
        what_on: row[12],
        financial_year_code: row[13]
      }.to_struct

      if old.present? && (old.entry_number != r.entry_number || old.printed_on != r.printed_on || old.journal != r.journal)
        if entry && entry[:items_attributes]
          je = JournalEntry.create!(entry)
          if je.real_debit != je.real_credit
            w.warn "Error on JournalEntry ##{entry[:number]} (D: #{je.debit}, C: #{je.credit}, B: #{je.debit - je.credit})"
          end
          entry = nil
        else
          fail 'What ???'
        end
      end

      # Adds the journal entry item with the dependencies
      unless entry
        fy = FinancialYear.at(r.printed_on)
        number = r.entry_number
        number = r.journal.code + (10_000_000_000 + rand(10_000_000_000)).to_s(36) if number.blank?
        number.upcase!
        number.succ! while used_numbers[number]
        used_numbers[number] = true
        entry = {
          printed_on: r.printed_on,
          journal: r.journal,
          number: number,
          financial_year: fy
        }
      end

      entry[:items_attributes] ||= {}
      entry[:items_attributes][index.to_s] = { real_debit: r.debit, real_credit: r.credit, account: r.account, name: r.entry_name }

      # Adds a real entity with known information
      if r.account.number =~ /^4(0|1)\d/
        last_name = r.entity_name.mb_chars.capitalize
        modified = false
        entities[last_name] ||= Entity.where('last_name ILIKE ?', last_name).first || Entity.create!(last_name: last_name, nature: 'organization', first_met_at: r.printed_on)
        entity = entities[last_name]
        if entity.first_met_at && r.printed_on && r.printed_on < entity.first_met_at
          entity.first_met_at = r.printed_on
          modified = true
        end
        account_number = r.account.number
        if account_number =~ /^401/
          entity.supplier = true
          entity.supplier_account_id = r.account.id
          modified = true
        end
        if account_number =~ /^411/
          entity.client = true
          entity.client_account_id = r.account.id
          modified = true
        end
        entity.save if modified
      end

      old = r
      count += 1
      w.check_point if count % w_count
    end

    count, entry, old, used_numbers, accounts, journals, entities = nil
  end
end
