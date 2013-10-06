class Backend::PlantMedicinesController < BackendController

  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :created_at
  end

  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :name, through: :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end

    # Liste des indicateurs de l'animal considéré
  list(:indicators, :model => :product_indicator_data, :conditions => [" product_id = ? ",'params[:id]'.c], :order => "created_at DESC") do |t|
    t.column :indicator
    t.column :measured_at
    t.column :value
  end

  #INDEX

  #SHOW

end
