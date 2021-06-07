namespace :maintenance do
  namespace :journal_entries do
    desc 'Fix some invalid datas in entries in for the FEC export to have correct'
    task fec_corrections: :environment do
      tenant = ENV['TENANT']
      started_on = Date.parse(ENV['STARTED_ON']) if ENV['STARTED_ON']
      stopped_on = Date.parse(ENV['STOPPED_ON']) if ENV['STOPPED_ON']

      if tenant
        Ekylibre::Tenant.switch(tenant) do
          puts "Switching to tenant #{tenant}".blue
          fix_datas(started_on, stopped_on)
        end
      else
        Ekylibre::Tenant.switch_each do |tenant|
          puts "Switching to tenant #{tenant}".blue
          fix_datas(started_on, stopped_on)
        end
      end
    end

    private

      def fix_datas(started_on, stopped_on)
        if started_on && stopped_on
          entries = JournalEntry.between(started_on, stopped_on)
        else
          fy = FinancialYear.current
          entries = fy.journal_entries
          if fy.previous && !fy.previous.closed
            entries += fy.previous.journal_entries
          end
        end

        puts "There are #{entries.count} to process".red

        # Problem on entry name where there are unwanted special caracters
        # Entry name depends on it's items name so first, we update the items name then we save the entry which will have a new name
        items = JournalEntryItem.where(entry_id: entries)

        ActiveRecord::Base.transaction do
          remove_unwanted_caracter(items, { unwanted_caracter: ';', replace_by: ',' })
          remove_unwanted_caracter(items, { unwanted_caracter: '"', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\n', method: :squish })
          remove_unwanted_caracter(items, { unwanted_caracter: '\|', replace_by: '-' })
          remove_unwanted_caracter(items, { unwanted_caracter: '&', replace_by: '-' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\?', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '<', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '>', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\=', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\*', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\^', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\$', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\~', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\`', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: "\t", replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\%', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\!', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '\§', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '#', replace_by: '' })
          remove_unwanted_caracter(items, { unwanted_caracter: '@', replace_by: '' })
        end
      end

      def remove_unwanted_caracter(items, options = {})
        # Set variables
        unwanted_caracter = options[:unwanted_caracter]
        raise "unwanted_caracter options needed" if unwanted_caracter.nil?

        replace_by = options[:replace_by]
        method = options[:method]
        raise "Either use replace_by or method but not both" if replace_by && method

        # Log
        if replace_by
          puts "Processing change of '#{unwanted_caracter}' in items name by a '#{replace_by}'".inspect.green
        else
          puts "Processing removal of '#{unwanted_caracter}' in items name".inspect.green
        end

        items_with_error = items.where("name ~* ?", unwanted_caracter)
        puts "#{items_with_error.count} items have a '#{unwanted_caracter}' in their name".inspect.blue
        return if items_with_error.empty?

        # Update all invalid items name
        items_with_error.each do |item|
          if replace_by
            new_name = item.name.tr(unwanted_caracter, replace_by)
          elsif method
            new_name = item.name.send(method)
          else
            raise "Can't remove caracter as there no way to do it with given arguments"
          end
          item.update_column(:name, new_name)
        end

        # Save entries items
        items_with_error.map(&:entry).uniq.map(&:save)
      end
  end
end
