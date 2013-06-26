class Backend::AnimalMedicinesController < BackendController

  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of animal_medicines.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => AnimalMedicine.all }
      format.json { render :json => AnimalMedicine.all }
    end
  end

  # Displays the page for one animal_medicine.
  def show
    return unless @animal_medicine = find_and_check
    respond_to do |format|
      format.html { t3e(@animal_medicine) }
      format.xml  { render :xml => @animal_medicine }
      format.json { render :json => @animal_medicine }
    end
  end
end
