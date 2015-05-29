# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::JournalsController < Backend::BaseController
  manage_restfully nature: "params[:nature]".c, currency: "Preference[:currency]".c

  unroll

  list(order: :name) do |t|
    t.column :name, url: true
    t.column :code, url: true
    t.column :nature
    t.column :currency
    t.column :closed_on
    # t.action :document_print, url: {:code => :JOURNAL, :journal => "RECORD.id"}
    t.action :close, if: :closable?, image: :unlock
    t.action :reopen, if: :reopenable?, image: :lock
    t.action :edit
    t.action :destroy
  end



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

  list(:items, model: :journal_entry_items, conditions: journal_entries_conditions, joins: :entry, line_class: "(RECORD.position==1 ? 'first-item' : '') + (RECORD.entry_balanced? ? '' : ' error')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
    t.column :entry_number, url: true
    t.column :printed_on, through: :entry, :datatype => :date
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

  list(:entries, model: :journal_entries, conditions: journal_entries_conditions, line_class: "(RECORD.balanced? ? '' : 'error')".c, order: {created_at: :desc}) do |t|
    t.column :number, url: true
    t.column :printed_on
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

  list(:mixed, model: :journal_entries, conditions: journal_entries_conditions, children: :items, line_class: "(RECORD.balanced? ? '' : 'error')".c, order: {created_at: :desc}, per_page: 10) do |t|
    t.column :number, url: true, :children => :name
    t.column :printed_on, :datatype => :date, :children => false
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
    t3e @journal
  end

  def close
    return unless @journal = find_and_check
    unless @journal.closable?
      notify(:no_closable_journal)
      redirect_to action: :index
      return
    end
    if request.post?
      if @journal.close(params[:closed_on].to_date)
        notify_success(:journal_closed_on, closed_on: @journal.closed_on.l, journal: @journal.name)
        redirect_to action: :index
      end
    end
    t3e @journal
  end

  def reopen
    return unless @journal = find_and_check
    unless @journal.reopenable?
      notify(:no_reopenable_journal)
      redirect_to action: :index
      return
    end
    if request.post?
      if @journal.reopen(params[:closed_on].to_date)
        notify_success(:journal_reopened_on, closed_on: @journal.closed_on.l, journal: @journal.name)
        redirect_to action: :index
      end
    end
    t3e @journal
  end


  list(:draft_items, model: :journal_entry_items, conditions: journal_entries_conditions(:with_journals => true, :state => :draft), joins: :entry, :line_class => "(RECORD.position==1 ? 'first-item' : '')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
    t.column :journal, url: true
    t.column :entry_number, url: true
    t.column :printed_on, :datatype => :date
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
    params[:stopped_on] = params[:stopped_on].to_date rescue Date.today
    params[:started_on] = params[:started_on].to_date rescue (params[:stopped_on] - 1.year).beginning_of_month
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
      session[:stopped_on] = params[:stopped_on]
      session[:started_on] = params[:started_on]
      @records = {}
      for nature in @natures
        conditions = ["created_at BETWEEN ? AND ?", session[:started_on].to_time.beginning_of_day, session[:stopped_on].to_time.end_of_day]
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
    t.column :printed_on
    t.column :name
    t.column :real_debit,  currency: :real_currency, hidden: true
    t.column :real_credit, currency: :real_currency, hidden: true
    t.column :debit,  currency: true, hidden: true
    t.column :credit, currency: true, hidden: true
    t.column :absolute_debit,  currency: :absolute_currency
    t.column :absolute_credit, currency: :absolute_currency
    t.column :cumulated_absolute_debit,  currency: :absolute_currency
    t.column :cumulated_absolute_credit, currency: :absolute_currency
  end

  def general_ledger
  end

end
