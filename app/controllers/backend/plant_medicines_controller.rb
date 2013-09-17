class Backend::PlantMedicinesController < BackendController

  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
    t.column :created_at
  end

  # Displays the main page with the list of animal_medicines.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => PlantMedicine.all }
      format.json { render :json => PlantMedicine.all }
    end
  end

  # Displays the page for one animal_medicine.
  def show
    return unless @plant_medicine = find_and_check
    respond_to do |format|
      format.html { t3e(@plant_medicine) }
      format.xml  { render :xml => @plant_medicine }
      format.json { render :json => @plant_medicine }
    end
  end

end
