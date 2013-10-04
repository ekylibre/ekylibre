class Backend::AnimalMedicinesController < BackendController

  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :net_volume
    t.column :net_weight
    t.column :milk_withdrawal_period
    t.column :meat_withdrawal_period
  end

end
