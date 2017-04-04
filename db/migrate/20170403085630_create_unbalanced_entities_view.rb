class CreateUnbalancedEntitiesView < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
					CREATE VIEW unbalanced_entities AS
          SELECT
						entities.id AS id,
						COALESCE(client_accountancy.balance, 0) AS client_accounting_balance,
						COALESCE(supplier_accountancy.balance, 0) AS supplier_accounting_balance,
						COALESCE(trade.balance, 0) AS trade_balance,
            0 AS lock_version
					FROM
						entities
					LEFT JOIN
						(SELECT
							entities.id AS entity_id,
							-SUM(client_items.balance) AS balance
						FROM entities
						JOIN accounts AS clients 
							ON entities.client_account_id = clients.id 
						JOIN journal_entry_items AS client_items 
							ON clients.id = client_items.account_id
						GROUP BY entities.id
						) AS client_accountancy
						ON entities.id = client_accountancy.entity_id 
					LEFT JOIN
						(SELECT
							entities.id AS entity_id,
							-SUM(supplier_items.balance) AS balance
						FROM entities
						JOIN accounts AS suppliers 
							ON entities.supplier_account_id = suppliers.id 
						JOIN journal_entry_items AS supplier_items 
							ON suppliers.id = supplier_items.account_id
						GROUP BY entities.id
						) AS supplier_accountancy
						ON entities.id = supplier_accountancy.entity_id
					LEFT JOIN 
						(SELECT
							entity_id AS entity_id,
							SUM(trades.amount) AS balance
						FROM
							(SELECT
								 entities.id AS entity_id,
								 -sale_items.amount AS amount
							 FROM entities 
							 JOIN sales 
								 ON entities.id = sales.client_id 
							 JOIN sale_items 
								 ON sales.id = sale_items.sale_id

							 UNION ALL
							 SELECT
								 entities.id AS entity_id,
								 incoming_payments.amount AS amount
							 FROM entities
							 JOIN incoming_payments 
								 ON entities.id = incoming_payments.payer_id
								 
							 UNION ALL
							 SELECT
								 entities.id AS entity_id,
								 purchase_items.amount AS amount
							 FROM entities
							 JOIN purchases
								 ON entities.id = purchases.supplier_id 
							 JOIN purchase_items 
								 ON purchases.id = purchase_items.purchase_id  

							 UNION ALL
							 SELECT
								 entities.id AS entity_id,
								 -outgoing_payments.amount AS amount
							 FROM entities
							 JOIN outgoing_payments 
								 ON entities.id = outgoing_payments.payee_id
						) AS trades
						GROUP BY entity_id
					) AS trade
						ON entities.id = trade.entity_id
					WHERE trade.balance != client_accountancy.balance
						OR trade.balance != supplier_accountancy.balance;
				SQL
			end

      dir.down do
        execute 'DROP VIEW unbalanced_entities;'
      end
    end
  end
end
