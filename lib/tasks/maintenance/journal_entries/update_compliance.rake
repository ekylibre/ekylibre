namespace :maintenance do
  namespace :journal_entries do
    desc 'Update compliance field for historical journal entries as it not filled in migration adding the field'
    task update_compliance: :environment do
      tenant = ENV['TENANT']
      started_on = Date.parse(ENV['STARTED_ON']) if ENV['STARTED_ON']
      stopped_on = Date.parse(ENV['STOPPED_ON']) if ENV['STOPPED_ON']

      if tenant
        Ekylibre::Tenant.switch(tenant) do
          puts "Switching to tenant #{tenant}".blue
          set_compliance(started_on, stopped_on)
        end
      else
        Ekylibre::Tenant.switch_each do |tenant|
          puts "Switching to tenant #{tenant}".blue
          set_compliance(started_on, stopped_on)
        end
      end
    end

    private

      # TODO: Disable triggers before processing for performance
      # For fermes-larrere tenant, task was about 7 hours long...
      def set_compliance(started_on, stopped_on)
        if started_on && stopped_on
          entries = JournalEntry.between(started_on, stopped_on)
        else
          fy = FinancialYear.current
          entries = fy.journal_entries
          if fy.previous && !fy.previous.closed
            entries = JournalEntry.where(financial_year_id: [fy.id, fy.previous.id])
          end
        end

        puts "There are #{entries.count} to process".red

        entries = entries.where("compliance = '{}'")
        puts "There are #{entries.count} left to process".blue

        entries.each_with_index do |je, _index|
          compliance = { vendor: :fec, name: :journal_entries, data: { errors: FEC::Check::JournalEntry.validate(je) } }
          je.update_column(:compliance, compliance)
        end
      end
  end
end
