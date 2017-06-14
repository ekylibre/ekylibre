module Backend
  class PayslipPaymentsController < Backend::OutgoingPaymentsController
    list(joins: :payee, order: { to_bank_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :payee, url: true
      t.column :paid_at
      t.column :amount, currency: true, url: true
      t.column :mode
      t.column :bank_check_number
      t.column :to_bank_at
      t.column :delivered, hidden: true
      t.column :work_name, through: :affair, label: :affair_number, url: { controller: :payslip_affairs }
      t.column :deal_work_name, through: :affair, label: :payslip_number, url: { controller: :payslips, id: 'RECORD.affair.deals_of_type(Payslip).first.id'.c }
      t.column :bank_statement_number, through: :journal_entry, url: { controller: :bank_statements, id: 'RECORD.journal_entry.bank_statements.first.id'.c }, label: :bank_statement_number
    end
  end
end
