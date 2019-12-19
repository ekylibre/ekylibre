module Backend
  module Cells
    class LastPanierLocalImportCellsController < Backend::Cells::BaseController
      def show
        finished_imports = Maybe(Import).finished

        last_sale_import = finished_imports
                              .where(nature: :panier_local_sales)
                              .reorder(:imported_at)
                              .last
        @ale_imported_count = last_sale_import
                                .fmap { |import| Sale.where('providers ->> ? = ?', 'import_id', import.id.to_s) }
                                .count
                                .or_else(0)

        last_incoming_payment_import = finished_imports
                                          .where(nature: :panier_local_incoming_payments)
                                          .reorder(:imported_at)
                                          .last
        @incoming_payment_imported_count = last_incoming_payment_import
                                             .fmap { |import| IncomingPayment.where('providers ->> ? = ?', 'import_id', import.id.to_s) }
                                             .count
                                             .or_else(0)

        @last_sale_import = last_sale_import.or_nil
        @last_incoming_payment_import = last_incoming_payment_import.or_nil
      end
    end
  end
end
