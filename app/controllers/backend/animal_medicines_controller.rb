class Backend::AnimalMedicinesController < BackendController

  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
  end

end
