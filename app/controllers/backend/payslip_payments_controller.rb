module Backend
  class PayslipPaymentsController < Backend::OutgoingPaymentsController

    def self.list_conditions
      fy = FinancialYear.current
      code = search_conditions(payslip_payments: %i[amount number], entities: %i[full_name]) + " ||= []\n"
      code << "if params[:mode].present?\n"
      code << " c[0] << ' AND #{PayslipPayment.table_name}.mode_id IN (?)'\n"
      code << " c << params[:mode]\n"
      code << "end\n"
      code << "if params[:amount].present?\n"
      code << " interval = params[:amount].split(',')\n"
      code << " c[0] << ' AND #{PayslipPayment.table_name}.amount BETWEEN ? AND ?'\n"
      code << " c << interval.first.to_i\n"
      code << " c << interval.last.to_i\n"
      code << "end\n"
      code << "if params[:bank_check_number].present?\n"
      code << " c[0] << ' AND #{PayslipPayment.table_name}.bank_check_number = ?'\n"
      code << " c << params[:bank_check_number]"
      code << "end\n"
      code << "if params[:paid_at].present? && params[:paid_at].to_s != 'all'\n"
      code << " c[0] << ' AND #{PayslipPayment.table_name}.paid_at::DATE BETWEEN ? AND ?'\n"
      code << " if params[:paid_at] == 'interval'\n"
      code << "   if params[:paid_at_started_on].present? && params[:paid_at_stopped_on].present?\n"
      code << "     c << params[:paid_at_started_on]\n"
      code << "     c << params[:paid_at_stopped_on]\n"
      code << "   elsif params[:paid_at_started_on].present? \n"
      code << "     c << params[:paid_at_started_on]\n"
      code << "     c << #{fy ? fy.stopped_on : Time.zone.today}\n"
      code << "   elsif params[:paid_at_stopped_on].present?\n"
      code << "     c << #{fy ? fy.started_on : Time.zone.today}\n"
      code << "     c << params[:paid_at_stopped_on]\n"
      code << "   end\n"
      code << " else\n"
      code << "   interval = params[:paid_at].to_s.split('_')\n"
      code << "   c << interval.first\n"
      code << "   c << interval.last\n"
      code << " end\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(joins: :payee, order: { to_bank_at: :desc }, conditions: list_conditions) do |t|
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
