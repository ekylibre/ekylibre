class FinancialYearExchangeImport
  class InvalidFile < RuntimeError; end

  attr_reader :error

  def initialize(file, exchange)
    @file = file
    @exchange = exchange
  end

  def run
    ActiveRecord::Base.transaction do
      read_and_parse_file || rollback!
      ensure_headers_are_valid || rollback!
      ensure_all_journals_exists || rollback!
      ensure_entries_included_in_financial_year_date_range || rollback!
      destroy_previous_journal_entries
      import_journal_entries || rollback!
      save_file
    end
    @error.blank?
  end

  private

  attr_reader :file, :exchange, :parsed

  def read_and_parse_file
    @parsed = CSV.parse(file.read, headers: true, header_converters: ->(header) { format_header(header) })
    true
  rescue => error
    message = I18n.translate('activerecord.errors.models.financial_year_exchange.csv_file_invalid')
    @error = InvalidFile.new(message)
    @internal_error = error
    false
  end

  def ensure_headers_are_valid
    expected = %i[jour numero_de_compte journal tiers numero_de_piece libelle_ecriture debit credit lettrage]
    return true if parsed.headers.to_set == expected.to_set
    message = I18n.translate('activerecord.errors.models.financial_year_exchange.csv_file_headers_invalid')
    @error = InvalidFile.new(message)
    false
  end

  def ensure_all_journals_exists
    journal_codes = parsed.map { |row| row[:journal] }.uniq
    existing_journal_codes = Journal.where(code: journal_codes).pluck(:code)
    return true if existing_journal_codes.length == journal_codes.length
    message = I18n.translate('activerecord.errors.models.financial_year_exchange.csv_file_journals_invalid', codes: (journal_codes - existing_journal_codes).join(', '))
    @error = InvalidFile.new(message)
    false
  end

  def ensure_entries_included_in_financial_year_date_range
    range = (exchange.financial_year.started_on..exchange.financial_year.stopped_on)
    return true if parsed.all? do |row|
      row_date = begin
                   Date.parse(row[:jour])
                 rescue
                   nil
                 end
      row_date && range.cover?(row_date)
    end
    message = I18n.translate('activerecord.errors.models.financial_year_exchange.csv_file_entry_dates_invalid')
    @error = InvalidFile.new(message)
    false
  end

  def destroy_previous_journal_entries
    financial_year = exchange.financial_year
    accountant = financial_year.accountant
    accountant.booked_journals.each do |journal|
      journal.entries.where(printed_on: financial_year.started_on..financial_year.stopped_on).find_each do |entry|
        entry.mark_for_exchange_import!
        entry.destroy
      end
    end
    true
  end

  def import_journal_entries
    import_journal_entries!
    true
  rescue => e
    @error = e
    false
  end

  def import_journal_entries!
    parsed.group_by { |row| row[:numero_de_piece] }.each do |entry_number, rows|
      sample_row = rows.first
      journal_code = sample_row[:journal]
      printed_on = sample_row[:jour]
      journal = Journal.find_by(accountant_id: exchange.financial_year.accountant_id, code: journal_code)
      next unless journal
      items = rows.each_with_object([]) do |row, array|
        array << {
          name: row[:libelle_ecriture],
          real_debit: row[:debit],
          real_credit: row[:credit],
          letter: row[:lettrage],
          account: Account.find_by(number: row[:numero_de_compte])
        }
      end
      entry = journal.entries.build(number: entry_number, printed_on: printed_on)
      entry.mark_for_exchange_import!
      entry.items_attributes = items
      save_entry! entry
    end
  end

  def save_entry!(entry)
    return true if entry.save && entry.confirm && entry.close
    message = I18n.translate('activerecord.errors.models.financial_year_exchange.csv_file_entry_invalid', entry_number: entry.number)
    @error = InvalidFile.new(message)
    @internal_error = ActiveRecord::RecordInvalid.new(entry)
    raise error
  end

  def save_file
    exchange.import_file = file
    @error = ActiveRecord::RecordInvalid.new(exchange) unless exchange.save
  end

  def format_header(header)
    I18n.transliterate(header.force_encoding('UTF-8')).underscore.gsub(/\s/, '_').to_sym
  end

  def rollback!
    raise ActiveRecord::Rollback
  end
end
