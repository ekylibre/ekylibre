class Backend::MedicinesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of animal_medicines.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Medicine.all }
      format.json { render :json => Medicine.all }
    end
  end

  # Displays the page for one animal_medicine.
  def show
    return unless @medicine = find_and_check
    respond_to do |format|
      format.html { t3e(@medicine) }
      format.xml  { render :xml => @medicine }
      format.json { render :json => @medicine }
    end
  end

end
