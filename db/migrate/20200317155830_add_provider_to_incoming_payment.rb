class AddProviderToIncomingPayment < ActiveRecord::Migration
  def change
    add_column :incoming_payments, :provider, :jsonb

    reversible do |dir|
      dir.up do
        query("CREATE INDEX incoming_payment_provider_index ON sales USING gin ((provider -> 'vendor'), (provider -> 'name'), (provider -> 'id'))")
      end
      dir.down do
        query("DROP INDEX incoming_payment_provider_index")
      end
    end
  end
end
