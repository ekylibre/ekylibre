module Backend
  class PayslipsController < Backend::BaseController
    manage_restfully

    unroll :number, :amount, :currency, :created_at, employee: :full_name

    def self.list_conditions
      code = search_conditions(payslip: [:number], entities: %i[last_name first_name full_name])
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
