module Backend
  class PayslipsController < Backend::BaseController
    manage_restfully

    unroll :number, :amount, :currency, :created_at, employee: :full_name

    def self.list_conditions
      code = search_conditions(payslip: [:number], entities: %i[last_name first_name full_name]) + " ||= []\n"
      code << "fy = FinancialYear.current\n"
      code << "if params[:status].present?\n"
      code << " if params[:status].include?('go') && (params[:status].include?('caution') || params[:status].include?('stop'))\n"
      code << "     c[0] << ' AND #{PayslipAffair.table_name}.id=#{Payslip.table_name}.affair_id AND #{PayslipAffair.table_name}.closed=true'\n"
      code << "   if params[:status].include?('caution')\n"
      code << "     c[0] << ' OR #{PayslipAffair.table_name}.deals_count>1'\n"
      code << "   end\n"
      code << "   if params[:status].include?('stop')\n"
      code << "     c[0] << ' OR #{PayslipAffair.table_name}.deals_count<=1'\n"
      code << "   end\n"
      code << " else\n"
      code << "   if params[:status].include? 'go'\n"
      code << "     c[0] << ' AND #{PayslipAffair.table_name}.id=#{Payslip.table_name}.affair_id AND #{PayslipAffair.table_name}.closed=true'\n"
      code << "   end\n"
      code << "   if params[:status].include?('caution') && params[:status].include?('stop')\n"
      code << "     c[0] << ' AND #{PayslipAffair.table_name}.id=#{Payslip.table_name}.affair_id AND #{PayslipAffair.table_name}.closed=false'\n"
      code << "   else\n"
      code << "     if params[:status].include? 'caution'\n"
      code << "       c[0] << ' AND #{PayslipAffair.table_name}.id=#{Payslip.table_name}.affair_id AND #{PayslipAffair.table_name}.closed=false AND #{PayslipAffair.table_name}.deals_count>1'\n"
      code << "     end\n"
      code << "     if params[:status].include? 'stop'\n"
      code << "       c[0] << ' AND #{PayslipAffair.table_name}.id=#{Payslip.table_name}.affair_id AND #{PayslipAffair.table_name}.closed=false AND #{PayslipAffair.table_name}.deals_count<=1'\n"
      code << "     end\n"
      code << "   end\n"
      code << " end\n"
      code << "end\n"
      code << "if params[:emitted_on].present? && params[:emitted_on].to_s != 'all'\n"
      code << " c[0] << ' AND #{Payslip.table_name}.emitted_on::DATE BETWEEN ? AND ?'\n"
      code << " if params[:emitted_on] == 'interval'\n"
      code << "   if params[:emitted_on_started_on].present? && params[:emitted_on_stopped_on].present?\n"
      code << "     c << params[:emitted_on_started_on]\n"
      code << "     c << params[:emitted_on_stopped_on]\n"
      code << "   elsif params[:emitted_on_started_on].present?\n"
      code << "     c << params[:emitted_on_started_on]\n"
      code << "     c << (fy ? fy.stopped_on : Time.zone.today)\n"
      code << "   elsif params[:emitted_on_stopped_on].present?\n"
      code << "     c << (fy ? fy.started_on : Time.zone.today)\n"
      code << "     c << params[:emitted_on_stopped_on]\n"
      code << "   end\n"
      code << " else\n"
      code << "   interval = params[:emitted_on].to_s.split('_')\n"
      code << "   c << interval.first\n"
      code << "   c << interval.last\n"
      code << " end\n"
      code << "end\n"
      code << "if params[:amount].present?\n"
      code << " interval = params[:amount].split(',')\n"
      code << " c[0] << ' AND #{Payslip.table_name}.amount BETWEEN ? AND ?'\n"
      code << " c << interval.first.to_i\n"
      code << " c << interval.last.to_i\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(joins: %i[affair employee], order: { emitted_on: :desc }, conditions: list_conditions) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :employee, url: true
      t.column :emitted_on
      t.column :amount, currency: true, on_select: :sum
      t.status
      t.column :affair_balance, currency: true, on_select: :sum, hidden: true
      t.column :started_on
      t.column :stopped_on
    end

    def correct
      return unless @payslip = find_and_check
      @payslip.correct
      redirect_to params[:redirect] || { action: :show, id: @payslip.id }
    end

    def invoice
      return unless @payslip = find_and_check
      @payslip.invoice
      redirect_to params[:redirect] || { action: :show, id: @payslip.id }
    end
  end
end
