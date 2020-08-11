class ReceptionBookkeeper < ParcelBookkeeper
  private

    def payables_not_billed_account
      :suppliers_invoices_not_received
    end
end
