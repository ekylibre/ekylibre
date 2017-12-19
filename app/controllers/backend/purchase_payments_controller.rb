module Backend
  class PurchasePaymentsController < Backend::OutgoingPaymentsController
    def self.list_conditions
      code = search_conditions(outgoing_payments: %i[amount bank_check_number number], entities: %i[number full_name]) + " ||= []\n"
      code << "if params[:s] == 'not_delivered'\n"
      code << "  c[0] += ' AND delivered = ?'\n"
      code << "  c << false\n"
      # code << "elsif params[:s] == 'waiting'\n"
      # code << "  c[0] += ' AND to_bank_at > ?'\n"
      # code << "  c << Time.zone.today\n"
      # code << "elsif params[:s] == 'not_closed'\n"
      # code << "  c[0] += ' AND used_amount != amount'\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, joins: :payee, order: { to_bank_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :payee, url: true
      t.column :paid_at
      t.column :amount, currency: true, url: true, on_select: :sum
      t.column :mode
      t.column :bank_check_number
      t.column :to_bank_at
      t.column :delivered, hidden: true
      t.column :work_name, through: :affair, label: :affair_number, url: { controller: :purchase_affairs }
      t.column :deal_work_name, through: :affair, label: :purchase_number, url: { controller: :purchase_invoices, id: 'RECORD.affair.deals_of_type(Purchase).first.id'.c }
      t.column :bank_statement_number, through: :journal_entry, url: { controller: :bank_statements, id: 'RECORD.journal_entry.bank_statements.first.id'.c }, label: :bank_statement_number
    end
  end
end
