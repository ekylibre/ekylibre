module Backend
  class SaleGapsController < Backend::GapsController
    list do |t|
      t.action :destroy
      t.column :number, url: true
      t.column :client, url: true
      t.column :direction
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true
      t.column :printed_at
    end
  end
end
