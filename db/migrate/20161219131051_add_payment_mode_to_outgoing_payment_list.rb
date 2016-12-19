class AddPaymentModeToOutgoingPaymentList < ActiveRecord::Migration
  def up
    add_reference :outgoing_payment_lists, :mode, index: true

    execute <<-SQL
      UPDATE "outgoing_payment_lists"
      SET "mode_id" = "outgoing_payments"."mode_id"
      FROM "outgoing_payments"
      WHERE "outgoing_payments"."list_id" = "outgoing_payment_lists"."id"
    SQL

    change_column_null :outgoing_payment_lists, :mode_id, false
  end

  def down
    change_column_null :outgoing_payment_lists, :mode_id, true
    remove_reference :outgoing_payment_lists, :mode
  end
end
