module JournalEntriesCondition
  extend ActiveSupport::Concern

  module ClassMethods
    def journal_entries_conditions(options = {})
      code = ''
      search_options = {}
      filter = { JournalEntryItem.table_name => %i[name debit credit] }
      unless options[:with_items]
        code << search_conditions(filter, conditions: 'cjel') + "\n"
        search_options[:filters] = { "#{JournalEntry.table_name}.id IN (SELECT entry_id FROM #{JournalEntryItem.table_name} WHERE \" + cjel[0] + \")" => 'cjel[1..-1]' }
        filter.delete(JournalEntryItem.table_name)
      end
      filter[JournalEntry.table_name] = %i[number debit credit]
      code << search_conditions(filter, search_options)
      if options[:with_journals]
        code << "\n"
        code << journals_crit('params')
      else
        code << "[0] += ' AND (#{JournalEntry.table_name}.journal_id=?)'\n"
        code << "c << params[:id]\n"
      end
      if options[:state]
        code << "c[0] += ' AND (#{JournalEntry.table_name}.state=?)'\n"
        code << "c << '#{options[:state]}'\n"
      else
        code << journal_entries_states_crit('params')
      end
      code << journal_period_crit('params')
      code << "c\n"
      # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      code.gsub(/\s*\n\s*/, ';').c
    end
  end
end
