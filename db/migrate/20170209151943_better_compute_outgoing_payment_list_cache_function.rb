class BetterComputeOutgoingPaymentListCacheFunction < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE OR REPLACE FUNCTION compute_outgoing_payment_list_cache() RETURNS TRIGGER AS
            $BODY$
              DECLARE
                new_id INTEGER DEFAULT NULL;
                old_id INTEGER DEFAULT NULL;
              BEGIN
                IF TG_OP <> 'DELETE' THEN
                  new_id := NEW.list_id;
                END IF;

                IF TG_OP <> 'INSERT' THEN
                  old_id := OLD.list_id;
                END IF;

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
                    AND ((new_id IS NOT NULL AND id = new_id)
                     OR  (old_id IS NOT NULL AND id = old_id));
                RETURN NEW;
              END
            $BODY$ language plpgsql;
        SQL
      end

      dir.down do
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
        SQL
      end
    end
  end
end
