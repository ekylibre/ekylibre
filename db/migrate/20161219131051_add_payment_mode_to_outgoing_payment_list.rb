class AddPaymentModeToOutgoingPaymentList < ActiveRecord::Migration
  def up
    add_reference :outgoing_payment_lists, :mode, index: true
    reversible do |r|
      r.up do
        execute <<-SQL.strip_heredoc
          UPDATE "outgoing_payment_lists"
            SET "mode_id" = "outgoing_payments"."mode_id"
            FROM "outgoing_payments"
            WHERE "outgoing_payments"."list_id" = "outgoing_payment_lists"."id"
SQL
      end
    end
    change_column_null :outgoing_payment_lists, :mode_id, false

    add_column :outgoing_payments, :position, :integer
  end
end
