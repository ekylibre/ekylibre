class AddPartialLetteringSupport < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE OR REPLACE FUNCTION compute_outgoing_payment_list_cache() RETURNS TRIGGER AS $$
          BEGIN
          SELECT substring(new.letter from '[A-z]*') AS letter,
                 account_id AS account_id,
                 SUM(debit) - SUM(credit) AS balance
              FROM journal_entry_items
              WHERE account_id = new.account_id
                AND letter ~ substring(new.letter from '[A-z]*')
              GROUP BY account_id;
          END;
          $$ language plpgpsql;

          CREATE TRIGGER compute_partial_lettering_status
            AFTER INSERT OR DELETE OR UPDATE OF credit, debit, balance, letter
            ON journal_entry_items
            FOR EACH ROW
              EXECUTE PROCEDURE compute_partial_lettering();
        SQL
      end

      dir.down do
        execute 'DROP TRIGGER IF EXISTS compute_partial_lettering_status;'
        execute 'DROP FUNCTION IF EXISTS compute_partial_lettering;'
      end
    end
  end
end
