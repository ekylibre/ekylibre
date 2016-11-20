module Backend
  class SaleAffairsController < Backend::AffairsController
    list do |t|
      t.column :number, url: true
      t.status
      t.column :debit, currency: true
      t.column :credit, currency: true
      t.column :closed, hidden: true
      t.column :closed_at
      t.column :client, url: true
      t.column :deals_count, hidden: true
      t.column :journal_entry, url: true
    end
  end
end
