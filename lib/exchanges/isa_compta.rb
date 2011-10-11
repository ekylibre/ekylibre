# encoding: utf-8
require File.join(File.dirname(__FILE__), 'svf')

module Exchanges

  class IsaCompta < Exchanger
    @@journal_natures = {
      "ac" => :purchases,
      "ve" => :sales,
      "tr" => :bank,
      # "tr" => :cash,
      "an" => :forward
    }


    def self.import(company, file, options={})
      version = nil
      File.open(file, "rb:CP1252") do |f|
        version = f.readline.to_s[13..16].to_i
      end
      used_versions = [8550]
      version = used_versions.select{|x| x <= version}.sort[-1]
      if version = 8550
        isa = SVF::Isa8550.parse(file)
        if isa_fy = isa.folder.financial_year
          # Find or create financial year
          unless fy = company.financial_years.find_by_started_on_and_stopped_on(isa_fy.started_on, isa_fy.stopped_on)
            if company.financial_years.where("? BETWEEN started_on AND stopped_on OR ? BETWEEN started_on AND stopped_on", isa_fy.started_on, isa_fy.stopped_on).count > 0
              raise ImcompatibleDataError.new("Financial year dates overlaps existing financial years")
            else
              raise ImcompatibleDataError.new("Accountancy must be in Euro (EUR) not in '#{isa_fy.currency}'") if isa_fy.currency != "EUR"
              fy = company.financial_years.create!(:started_on=>isa_fy.started_on, :stopped_on=>isa_fy.stopped_on)
            end
          end

          # Ignore Analytics data

          # Adds missing accounts
          all_accounts = {}
          for isa_account in isa_fy.accounts
            unless account = company.accounts.find_by_number(isa_account.number)
              account = company.accounts.create!(:name=>(isa_account.label.blank? ? isa_account.number : isa_account.label), :number=>isa_account.number, :reconcilable=>isa_account.reconcilable, :last_letter=>isa_account.letter, :is_debit=>(isa_account.input_direction=='de' ? true : false), :comment=>isa_account.to_s)
            end
            all_accounts[isa_account.number] = account.id
          end

          # Ignore taxes

          # Add journals
          all_journals = {}
          for isa_journal in isa_fy.journals
            journal = nil
            journals = company.journals.where("TRANSLATE(LOWER(name), 'àâäéèêëìîïòôöùûüỳŷÿ', 'aaaeeeeiiiooouuuyyy') LIKE ? ", '%'+isa_journal.label.gsub(/\s+/, '%')+'%')
            journal = journals[0] if journals.size == 1
            journal ||= company.journals.create!(:code=>isa_journal.code, :name=>"[#{isa_journal.code}] #{isa_journal.label}", :nature=>@@journal_natures[isa_journal.type]||:various) # , :closed_on=>isa_journal.last_close_on
            all_journals[isa_journal.code] = journal.id
          end
          
          for isa_entry in isa_fy.entries
            unless entry = company.journal_entries.find_by_number_and_journal_id(isa_entry.number, all_journals[isa_entry.journal])
              entry = company.journal_entries.create!(:number=>isa_entry.number, :journal_id=>all_journals[isa_entry.journal], :printed_on=>isa_entry.printed_on, :created_on=>isa_entry.created_on, :updated_at=>isa_entry.updated_on, :lock_version=>isa_entry.version_number) # , :state=>(isa_entry.unupdateable? ? :confirmed : :draft)
            end
            entry.lines.clear
            for isa_line in isa_entry.lines
              entry.lines.create!(:account_id=>all_accounts[isa_line.account], :name=>"#{isa_line.label} (#{isa_entry.label})", :currency_debit=>isa_line.debit, :currency_credit=>isa_line.credit, :letter=>(isa_line.lettering > 0 ? isa_line.letter : nil), :comment=>isa_line.to_s)
            end
          end
          
          

        end


      else
        raise NotWellFormedFileError.new("Version does not seems to be supported")
      end
      
    end

  end

end
