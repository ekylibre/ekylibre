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

module Backend
  class AccountsController < Backend::BaseController
    manage_restfully number: 'params[:number]'.c

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    before_action :save_search_preference, only: %i[index mark show]

    def self.accounts_conditions
      code = ''
      code << search_conditions(accounts: %i[name number description]) + ';'
      code << "if params[:prefix]\n"
      code << "  c[0] += ' AND number LIKE ?'\n"
      code << "  c << params[:prefix].to_s+'%'\n"
      code << "end\n"
      code << "unless params[:period].blank? or params[:period]='all'\n"
      code << "  c[0] += ' AND id IN (SELECT account_id FROM #{JournalEntryItem.table_name} AS jel JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id) WHERE '+JournalEntry.period_condition(params[:period], params[:started_on], params[:stopped_on], 'je')+')'\n"
      code << "end\n"
      code << "c\n"
      # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      code.c
    end

    list(conditions: accounts_conditions, order: :number, per_page: 20) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :name, url: true
      t.column :usages, hidden: true
      t.column :nature
      t.column :description
    end

    # Displays the main page with the list of accounts
    def index; end

    def show
      return unless @account = find_and_check
      t3e @account
      respond_to do |format|
        format.html {}
        format.odt do
          get_dataset_account
          if params[:non_letter] == 'true'
            filename = :extract_unlettered_account_x.tl(account_number: @account.number).tr(' ', '_')
            send_data non_letter_odt.generate, type: 'application/vnd.oasis.opendocument.text', disposition: 'attachment', filename: filename << '.odt'
          else
            filename = :extract_account_x.tl(account_number: @account.number).tr(' ', '_')
            send_data to_odt.generate, type: 'application/vnd.oasis.opendocument.text', disposition: 'attachment', filename: filename << '.odt'
          end
        end
        format.pdf do
          if params[:template].present?
            respond_with(@account, methods: [],
                                   include: [
                                     { journal_entry_items: { include: %i[financial_year tax tax_declaration_item] } }
                                   ],
                                   procs: proc { |options| options[:builder].tag!(:url, backend_account_url(@account)) })
          else
            get_dataset_account
            to_pdf
          end
        end
      end
    end

    def self.account_moves_conditions(_options = {})
      code = ''
      code << search_conditions({ journal_entry_item: %i[name debit credit real_debit real_credit], journal_entry: [:number], product_nature_variant: [:name] }, conditions: 'c', variable: 'params[:b]'.c) + "\n"
      code << journal_period_crit('params')
      code << journal_entries_states_crit('params')
      # code << journals_crit("params")
      code << "c[0] << ' AND #{JournalEntryItem.table_name}.account_id = ?'\n"
      code << "c << params[:id]\n"
      code << "c\n"
      code.c
    end

    list(:journal_entry_items, joins: :entry, conditions: account_moves_conditions, line_class: "(RECORD.completely_lettered? ? 'lettered-item' : '')".c, order: "entry_id DESC, #{JournalEntryItem.table_name}.position") do |t|
      t.column :journal, url: true
      t.column :entry_number, url: true
      t.column :printed_on, datatype: :date, label: :column
      t.column :name
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :state_label
      t.column :letter
      t.column :real_debit,  currency: :real_currency, hidden: true
      t.column :real_credit, currency: :real_currency, hidden: true
      t.column :debit,  currency: true, hidden: true
      t.column :credit, currency: true, hidden: true
      t.column :absolute_debit,  currency: :absolute_currency, on_select: :sum
      t.column :absolute_credit, currency: :absolute_currency, on_select: :sum
    end

    list(:entities, conditions: ['? IN (client_account_id, supplier_account_id)', 'params[:id]'.c], order: { created_at: :desc }) do |t|
      t.column :number, url: true
      t.column :full_name, url: true
      t.column :client_account, url: true
      t.column :supplier_account, url: true
    end

    list(:product_nature_variants, joins: :category, conditions: ['? IN (product_nature_categories.charge_account_id, product_nature_categories.product_account_id, product_nature_categories.fixed_asset_account_id, product_nature_categories.stock_account_id)', 'params[:id]'.c], order: { created_at: :desc }) do |t|
      t.column :number, url: { namespace: :backend }
      t.column :name, url: { namespace: :backend }
    end

    def self.account_reconciliation_conditions
      code = search_conditions(accounts: %i[name number]) + "[0] += ' AND reconcilable = ?'\n"
      code << "c << true\n"
      code << account_lettering_states_crit('params')
      code << 'c'
      code.c
    end

    list(:reconciliation, model: :accounts, conditions: account_reconciliation_conditions, order: 'accounts.number', distinct: true) do |t|
      t.column :number, label_method: :number, url: { action: :mark }
      t.column :name, label_method: :name, url: { action: :mark }
    end

    def reconciliation; end

    def mark
      return unless @account = find_and_check
      if request.post?
        if params[:journal_entry_item]
          letter = @account.mark(params[:journal_entry_item].select { |_k, v| v[:to_mark].to_i == 1 }.collect { |k, _v| k.to_i })
          if letter.nil?
            notify_error_now(:cannot_mark_entry_items)
          else
            notify_success_now(:journal_entry_items_marked_with_letter, letter: letter)
          end
        else
          notify_warning_now(:select_entry_items_to_mark_together)
        end
      end
      t3e @account.attributes
    end

    def unmark
      return unless @account = find_and_check
      @account.unmark(params[:letter]) if params[:letter]
      redirect_to_back
    end

    def reconciliable_list
      return unless @account = Account.find_by_id(params[:id])

      if params.key?(:masked)
        preference_name = 'backend/accounts'
        preference_name << ".#{params[:context]}" if params[:context]
        preference_name << '.lettered_items.masked'
        current_user.prefer!(preference_name, params[:masked].to_s == 'true', :boolean)
      end

      lettered_items_preference = current_user.preference(preference_name, 'true', :boolean)

      @items = @account.reconcilable_entry_items(params[:period], params[:started_on], params[:stopped_on], hide_lettered: lettered_items_preference.value)

      @unmark_label = :unmark.ta
      @unmark_title = :unmark.tl
      @confirm_label = :are_you_sure.tl
      @account_id = @account.id
      @currency = Preference[:currency]
      @precision = Nomen::Currency[@currency].precision

    end

    def mask_lettered_items
      preference_name = 'backend/accounts'
      preference_name << ".#{params[:context]}" if params[:context]
      preference_name << '.lettered_items.masked'
      current_user.prefer!(preference_name, params[:masked].to_s == 'true', :boolean)
      head :ok
    end

    def filter_select_collection
      regexp = /\A#{Regexp.quote(params[:filter_value].first(3))}/
      @filtered_accounts = Nomen::Account.list.reject { |a| a.send(Account.accounting_system) == 'NONE' || !a.send(Account.accounting_system).match(regexp) }
      @filtered_accounts = @filtered_accounts.sort_by { |a| a.send(Account.accounting_system) }
    end

    protected

     #TODO: Move this into a `Printer` service class.
    def get_dataset_account
      @dataset_account = @account.account_statement_reporting(params[:non_letter])
    end

    def to_pdf
      if params[:non_letter] == 'true'
        filename = :extract_unlettered_account_x.tl(account_number: @account.number).tr(' ', '_')
        file_odt = non_letter_odt.generate
      else
        filename = :extract_account_x.tl(account_number: @account.number).tr(' ', '_')
        file_odt = to_odt.generate
      end
      generate_pdf_from_odt(file_odt, filename)
    end

    def generate_pdf_from_odt(file_odt, filename)
      tmp_dir = Ekylibre::Tenant.private_directory.join('tmp')
      uuid = SecureRandom.uuid
      source = tmp_dir.join(uuid + '.odt')
      dest = tmp_dir.join(uuid + '.pdf')
      FileUtils.mkdir_p tmp_dir
      File.write source, file_odt
      `soffice  --headless --convert-to pdf --outdir #{Shellwords.escape(tmp_dir.to_s)} #{Shellwords.escape(source)}`
      send_data(File.read(dest), type: 'application/pdf', disposition: 'attachment', filename: filename + '.pdf')
    end

    def non_letter_odt
      ODFReport::Report.new(Rails.root.join('config', 'locales', 'fra', 'reporting', 'account_statement_non_letter.odt')) do |r|
        r.add_table('ITEM1', @dataset_account[:items], header: true) do |t|
          add_columns_to_odt(t, false)
        end
      end
    end

    def to_odt
      # add a generic template system path
      ODFReport::Report.new(Rails.root.join('config', 'locales', 'fra', 'reporting', 'account_statement.odt')) do |r|
        r.add_table('ITEM1', @dataset_account[:items], header: true) do |t|
          add_columns_to_odt(t, true)
        end
      end
    end

    def add_columns_to_odt(t, letter)
      t.add_column(:account_number) { |item| item[:account_number] }
      t.add_column(:name)
      t.add_column(:printed_on)
      t.add_column(:journal_entry_items_number)
      t.add_column(:sales_code)
      t.add_column(:purchase_reference_number)
      t.add_column(:letter) if letter
      t.add_column(:real_debit)
      t.add_column(:real_credit)
    end
  end
end
