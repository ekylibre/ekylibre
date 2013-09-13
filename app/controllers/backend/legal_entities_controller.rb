class Backend::LegalEntitiesController < Backend::EntitiesController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

end
