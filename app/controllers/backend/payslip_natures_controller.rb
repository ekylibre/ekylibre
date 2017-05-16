module Backend
  class PayslipNaturesController < Backend::BaseController
    manage_restfully currency: 'Preference[:currency]'.c

    unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :active
      t.column :currency
      t.column :with_accounting
      t.column :journal, url: true
      t.column :account, url: true
    end
  end
end
