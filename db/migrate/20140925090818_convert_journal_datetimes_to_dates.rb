class ConvertJournalDatetimesToDates < ActiveRecord::Migration

  def change
    for table, columns in {journals: [:closed_at], journal_entries: [:printed_at], journal_entry_items: [:printed_at]}
      for column_name in columns
        new_column_name = column_name.to_s.gsub(/\_at$/, '_on').to_sym
        rename_column table, column_name, new_column_name
        change_column table, new_column_name, :date
      end
    end
  end

end
