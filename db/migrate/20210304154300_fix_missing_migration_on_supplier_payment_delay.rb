class FixMissingMigrationOnSupplierPaymentDelay < ActiveRecord::Migration[4.2]
  def up
    transcode_payment_delay = [
      ["0 days", "1 week"],
      ["0 jour", "1 week"],
      ["0 jours", "1 week"],
      ["8 jours", "1 week"],
      ["10 jours", "1 week"],
      ["10 jours ", "1 week"],
      ["15 jours", "1 week"],
      ["20 jours", "1 week"],
      ["25 jours", "30 days"],
      ["30 jours", "30 days"],
      ["30 jours, fdm", "30 days, end of month"],
      ["30 jours,fdm", "30 days, end of month"],
      ["45 jours", "60 days"],
      ["45 jours, fdm", "60 days, end of month"],
      ["50 jours", "60 days"],
      ["60 jours", "60 days"]
    ]
    transcode_payment_delay.each do |delay|
      execute <<-SQL
        UPDATE entities AS e
        SET supplier_payment_delay = '#{delay[1]}'
        WHERE supplier_payment_delay IS NOT NULL
          AND supplier = TRUE
          AND supplier_payment_delay = '#{delay[0]}';
      SQL
    end
  end

  def down
    # NOOP
  end
end
