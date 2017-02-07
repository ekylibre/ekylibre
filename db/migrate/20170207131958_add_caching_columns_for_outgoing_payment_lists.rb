class AddCachingColumnsForOutgoingPaymentLists < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        add_column :outgoing_payment_lists, :cached_payment_count, :integer
        add_column :outgoing_payment_lists, :cached_total_sum, :decimal
        execute <<-SQL
          CREATE OR REPLACE FUNCTION compute_outgoing_payment_list_cache() RETURNS TRIGGER AS $$
          BEGIN
            UPDATE outgoing_payment_lists
               SET cached_payment_count = payments.count,
                   cached_total_sum = payments.total
              FROM (
                SELECT outgoing_payments.list_id AS list_id,
                       SUM(outgoing_payments.amount) AS total,
                       COUNT(outgoing_payments.id) AS count
                  FROM outgoing_payments
                  GROUP BY outgoing_payments.list_id
              ) AS payments
              WHERE payments.list_id = id
                AND ((TG_OP <> 'DELETE' AND id = NEW.list_id)
                 OR  (TG_OP <> 'INSERT' AND id = OLD.list_id));
            RETURN NEW;
          END;
          $$ language plpgsql;

          UPDATE outgoing_payment_lists
             SET cached_payment_count = payments.count,
                 cached_total_sum = payments.total
            FROM (
              SELECT outgoing_payments.list_id AS list_id,
                     SUM(outgoing_payments.amount) AS total,
                     COUNT(outgoing_payments.id) AS count
                FROM outgoing_payments
                GROUP BY outgoing_payments.list_id
            ) AS payments
            WHERE payments.list_id = id;

          CREATE TRIGGER outgoing_payment_list_cache
            AFTER INSERT OR DELETE OR UPDATE OF list_id, amount ON outgoing_payments
            FOR EACH ROW
              EXECUTE PROCEDURE compute_outgoing_payment_list_cache();
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP TRIGGER IF EXISTS outgoing_payment_list_cache ON outgoing_payments;
          DROP FUNCTION IF EXISTS compute_outgoing_payment_list_cache();
        SQL
        remove_column :outgoing_payment_lists, :cached_payment_count
        remove_column :outgoing_payment_lists, :cached_total_sum
      end
    end
  end
end
