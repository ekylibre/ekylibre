# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::JournalsController < BackendController
  manage_restfully :nature => "params[:nature]".c, :currency => "Preference[:currency]".c

  unroll

  hide_action :journal_views

  @@journal_views = ["items", "entries", "mixed"]
  cattr_reader :journal_views

  def self.journal_entries_conditions(options={})
    code = ""
    search_options = {}
    filter = {JournalEntryItem.table_name => [:name, :debit, :credit]}
    unless options[:with_items]
      code << search_conditions(filter, conditions: "cjel")+"\n"
      search_options[:filters] = {"#{JournalEntry.table_name}.id IN (SELECT entry_id FROM #{JournalEntryItem.table_name} WHERE '+cjel[0]+')" => "cjel[1..-1]"}
      filter.delete(JournalEntryItem.table_name)
    end
    filter[JournalEntry.table_name] = [:number, :debit, :credit]
    code << search_conditions(filter, search_options)
    if options[:with_journals]
      code << "\n"
      code << journals_crit("params")
    else
      code << "[0] += ' AND (#{JournalEntry.table_name}.journal_id=?)'\n"
      code << "c << params[:id]\n"
    end
    if options[:state]
      code << "c[0] += ' AND (#{JournalEntry.table_name}.state=?)'\n"
      code << "c << '#{options[:state]}'\n"
    else
      code << journal_entries_states_crit("params")
    end
    code << journal_period_crit("params")
    code << "c\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return code.gsub(/\s*\n\s*/, ";").c
  end

  list(:items, model: :journal_entry_items, conditions: journal_entries_conditions, joins: :entry, :line_class => "(RECORD.position==1 ? 'first-item' : '')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
    t.column :entry_number, url: true
    t.column :printed_at, through: :entry, :datatype => :date
    t.column :account, url: true
    t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
    t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
    t.column :name
    t.column :state_label
    t.column :real_debit,  currency: :real_currency
    t.column :real_credit, currency: :real_currency
    t.column :debit,  currency: true, hidden: true
    t.column :credit, currency: true, hidden: true
    t.column :absolute_debit,  currency: :absolute_currency, hidden: true
    t.column :absolute_credit, currency: :absolute_currency, hidden: true
  end

  list(:entries, model: :journal_entries, conditions: journal_entries_conditions, order: {created_at: :desc}) do |t|
    t.column :number, url: true
    t.column :printed_at
    t.column :state_label
    t.column :real_debit,  currency: :real_currency
    t.column :real_credit, currency: :real_currency
    t.column :debit,  currency: true, hidden: true
    t.column :credit, currency: true, hidden: true
    t.column :absolute_debit,  currency: :absolute_currency, hidden: true
    t.column :absolute_credit, currency: :absolute_currency, hidden: true
    t.action :edit, if: :updateable?
    t.action :destroy, if: :destroyable?
  end

  # FIXME RECORD.real_currency does not exist
  list(:mixed, model: :journal_entries, conditions: journal_entries_conditions, :children => :items, order: {created_at: :desc}, :per_page => 10) do |t|
    t.column :number, url: true, :children => :name
    t.column :printed_at, :datatype => :date, :children => false
    # t.column :label, through: :account, url: {action: :account}
    t.column :state_label
    t.column :real_debit,  currency: :real_currency
    t.column :real_credit, currency: :real_currency
    t.column :debit,  currency: true, hidden: true
    t.column :credit, currency: true, hidden: true
    t.column :absolute_debit,  currency: :absolute_currency, hidden: true
    t.column :absolute_credit, currency: :absolute_currency, hidden: true
    t.action :edit, if: :updateable?
    t.action :destroy, if: :destroyable?
  end

  #FIXME undefined method `human_name' for nil:NilClass
  list(order: :code) do |t|
    t.column :name, url: true
    t.column :code, url: true
    t.column :nature
    #t.column :currency
    t.column :closed_at
    # t.action :document_print, url: {:code => :JOURNAL, :journal => "RECORD.id"}
    t.action :close, if: 'RECORD.closable?(Date.today)'.c, image: :unlock
    t.action :reopen, if: :reopenable?, image: :lock
    t.action :edit
    t.action :destroy
  end

  # Displays details of one journal selected with +params[:id]+
  def show
    return unless @journal = find_and_check
    journal_view = current_user.preference("interface.journal.#{@journal.code}.view")
    journal_view.value = self.journal_views[0] unless self.journal_views.include? journal_view.value
    if view = self.journal_views.detect{|x| params[:view] == x}
      journal_view.value = view
      journal_view.save
    end
    @journal_view = journal_view.value
    t3e @journal.attributes
  end

  def close
    return unless @journal = find_and_check
    unless @journal.closable?
      notify(:no_closable_journal)
      redirect_to action: :index
      return
    end
    if request.post?
      if @journal.close(params[:journal][:closed_at].to_date)
        notify_success(:journal_closed_at, :closed_at => ::I18n.l(@journal.closed_at), :journal => @journal.name)
        redirect_to_back
      end
    end
    t3e @journal.attributes
  end

  def reopen
    return unless @journal = find_and_check
    unless @journal.reopenable?
      notify(:no_reopenable_journal)
      redirect_to action: :index
      return
    end
    if request.post?
      if @journal.reopen(params[:journal][:closed_at].to_date)
        notify_success(:journal_reopened_at, :closed_at => ::I18n.l(@journal.closed_at), :journal => @journal.name)
        redirect_to_back
      end
    end
    t3e @journal.attributes
  end

  # Displays the main page with the list of journals
  def index
  end


  # FIXME RECORD.real_currency does not exist
  list(:draft_items, model: :journal_entry_items, conditions: journal_entries_conditions(:with_journals => true, :state => :draft), joins: :entry, :line_class => "(RECORD.position==1 ? 'first-item' : '')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
    t.column :journal, url: true
    t.column :entry_number, url: true
    t.column :printed_at, :datatype => :date
    t.column :account, url: true
    t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
    t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
    t.column :name
    t.column :real_debit,  currency: :real_currency, hidden: true
    t.column :real_credit, currency: :real_currency, hidden: true
    t.column :debit,  currency: true
    t.column :credit, currency: true
    t.column :absolute_debit,  currency: :absolute_currency, hidden: true
    t.column :absolute_credit, currency: :absolute_currency, hidden: true
  end

  # this method lists all the entries generated in draft mode.
  def draft
    if request.post? and params[:validate]
      conditions = nil
      begin
        conditions = eval(self.class.journal_entries_conditions(:with_journals => true, :state => :draft))
        journal_entries = JournalEntry.where(conditions)
        undone = 0
        for entry in journal_entries
          entry.confirm if entry.can_confirm?
          undone += 1 if entry.draft?
        end
        notify_success_now(:draft_entry_items_are_validated, :count => journal_entries.size-undone)
      rescue Exception => e
        notify_error_now(:exception_raised, :message => e.message)
      end
    end
  end


  def bookkeep
    params[:stopped_at] = params[:stopped_at].to_date rescue Date.today
    params[:started_at] = params[:started_at].to_date rescue (params[:stopped_at] - 1.year).beginning_of_month
    @natures = [:sale, :incoming_payment, :deposit, :purchase, :outgoing_payment, :cash_transfer, :affair] # , transfer

    if request.get?
      notify_now(:bookkeeping_works_only_with, :list => @natures.collect{|x| x.to_s.classify.constantize.model_name.human}.to_sentence)
      @step = 1
    elsif request.put?
      @step = 2
    elsif request.post?
      @step = 3
    end

    if @step >= 2
      session[:stopped_at] = params[:stopped_at]
      session[:started_at] = params[:started_at]
      @records = {}
      for nature in @natures
        conditions = ["created_at BETWEEN ? AND ?", session[:started_at].to_time.beginning_of_day, session[:stopped_at].to_time.end_of_day]
        @records[nature] = nature.to_s.classify.constantize.where(conditions)
      end

      if @step == 3
        state = (params[:save_in_draft].to_i == 1 ? :draft : :confirmed)
        for nature in @natures
          for record in @records[nature]
            record.bookkeep(:create, state)
          end
        end
        notify_success(:bookkeeping_is_finished)
        redirect_to action: (state == :draft ? :draft : :bookkeep)
      end
    end

  end


  def balance
    if params[:period]
      @balance = Journal.balance(params)
    end
  end

  def self.general_ledger_conditions(options={})
    conn = ActiveRecord::Base.connection
    code = ""
    code << search_conditions({:journal_entry_item => [:name, :debit, :credit, :real_debit, :real_credit]}, conditions: "c")+"\n"
    code << journal_period_crit("params")
    code << journal_entries_states_crit("params")
    code << accounts_range_crit("params")
    code << journals_crit("params")
    code << "c\n"
    # code.split("\n").each_with_index{|x, i| puts((i+1).to_s.rjust(4)+": "+x)}
    return code.c # .gsub(/\s*\n\s*/, ";")
  end

  # FIXME RECORD.real_currency does not exist
  list(:general_ledger, model: :journal_entry_items, conditions: general_ledger_conditions, joins: [:entry, :account], order: "accounts.number, journal_entries.number, #{JournalEntryItem.table_name}.position") do |t|
    t.column :account, url: true
    t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
    t.column :account_name, through: :account, label_method: :name, url: true, hidden: true
    t.column :entry_number, url: true
    t.column :printed_at
    t.column :name
    t.column :real_debit,  currency: :real_currency, hidden: true
    t.column :real_credit, currency: :real_currency, hidden: true
    t.column :debit,  currency: true, hidden: true
    t.column :credit, currency: true, hidden: true
    t.column :absolute_debit,  currency: :absolute_currency
    t.column :absolute_credit, currency: :absolute_currency
  end

  def general_ledger
  end

  # TODO: Removes totally this old action in next buug cleaning
  # def reports()
  #   # redirect_to action: :index
  #   @document_templates = DocumentTemplate.where(:family => "accountancy", :nature => ["journal", "general_journal", "general_ledger"]).order(:name)
  #   @document_template = DocumentTemplate.find_by_family_and_code("accountancy", params[:code])
  #   if request.xhr?
  #     render :partial => 'options'
  #     return
  #   end
  #   if params[:export] == "balance"
  #     query  = "SELECT ''''||accounts.number, accounts.name, sum(COALESCE(journal_entry_items.debit, 0)), sum(COALESCE(journal_entry_items.credit, 0)), sum(COALESCE(journal_entry_items.debit, 0)) - sum(COALESCE(journal_entry_items.credit, 0))"
  #     query += " FROM #{JournalEntryItem.table_name} AS journal_entry_items JOIN #{Account.table_name} AS accounts ON (account_id=accounts.id) JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id)"
  #     query += " WHERE printed_at BETWEEN #{ActiveRecord::Base.connection.quote(params[:started_at].to_date)} AND #{ActiveRecord::Base.connection.quote(params[:stopped_at].to_date)}"
  #     query += " GROUP BY accounts.name, accounts.number"
  #     query += " ORDER BY accounts.number"
  #     begin
  #       result = ActiveRecord::Base.connection.select_rows(query)
  #       result.insert(0, ["N°Compte", "Libellé du compte", "Débit", "Crédit", "Solde"])
  #       result.insert(0, ["Balance du #{params[:started_at]} au #{params[:stopped_at]}"])
  #       csv_string = Ekylibre::CSV.generate do |csv|
  #         for item in result
  #           csv << item
  #         end
  #       end
  #       send_data(csv_string, :filename => 'export.csv', :type => Mime::CSV)
  #     rescue Exception => e
  #       notify_error_now(:exception_raised, :message => e.message)
  #     end
  #   elsif params[:export] == "isaquare"
  #     path = Ekylibre::Export::AccountancySpreadsheet.generate(params[:started_at].to_date, params[:stopped_at].to_date, Entity.of_company.full_name.simpleize+".ECC")
  #     send_file(path, :filename => path.basename, :type => Mime::ZIP)
  #   elsif params[:template]
  #     template = DocumentTemplate.find_by_code(params[:template])
  #     nature = template.nature.to_sym
  #     if [:balance_sheet, :income_statement].include?(nature)
  #       send("render_print_#{nature}", FinancialYear.find_by_id(params[:financial_year_id]))
  #     elsif [:general_journal, :general_ledger].include?(nature)
  #       send("render_print_#{nature}", params[:started_at], params[:stopped_at])
  #     elsif [:journal].include?(nature)
  #       send("render_print_#{nature}", Journal.find_by_id(params[:journal_id]), params[:started_at], params[:stopped_at])
  #     end
  #   end
  #   @document_template ||= @document_templates[0]
  # end





  def import
    @supported_files = [["COTFW.ISA", :isa_compta]]
    if request.post?
      data = params[:upload]
      file = Rails.root.join("tmp", "upload-#{data.original_filename}.#{rand.to_s[2..-1].to_i.to_s(36)}")
      File.open(file, "wb") {|f| f.write(data.read)}
      nature = params[:nature].to_sym rescue nil
      logger.silence do
        Exchanges.import(nature, file)
        begin
        rescue Exception => e
          notify_error_now(:exception_raised, :message => e.message)
        end
      end
    end
  end


end
