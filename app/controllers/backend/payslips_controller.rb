module Backend
  class PayslipsController < Backend::BaseController
    manage_restfully

    unroll :number, :amount, :currency, :created_at, employee: :full_name

    def index
      notify_warning_now(:no_saved_a_x_html, x: helpers.link_to(PayslipNature.model_name.human, backend_payslip_natures_path), html: true) if PayslipNature.count.zero?

      super
    end

    list(joins: %i[affair employee], order: { emitted_on: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :employee, url: true
      t.column :emitted_on
      t.column :amount, currency: true, on_select: :sum
      t.status
      t.column :state_label, hidden: true
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
