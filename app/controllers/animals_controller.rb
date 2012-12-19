# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class AnimalsController < AdminController
  manage_restfully :multipart => true

  list do |t|
    t.column :identification_number, :url => true
    t.column :name, :url=>true
    t.column :name, :through=>:group, :url=>true
    t.column :born_on
    t.column :sex
    t.column :name, :through=>:mother, :url=>true
    t.column :income_on
    t.column :outgone_on
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  # Show a list of animal groups

  def index
    @animals = Animal.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @animals }
      # Example: Basic Usage
      format.pdf { render_animals_list(@animals) }
    end
  end

  # Liste des soins de l'animal considéré
  list(:events, :model=>:animal_events, :conditions=>{:animal_id=>['session[:current_animal_id]']}, :order=>"started_on ASC") do |t|
    t.column :name, :url=>true
    t.column :name ,:through => :nature
    t.column :name ,:through => :watcher
    t.column :started_on
    t.column :comment
  end

  # Liste des enfants de l'animal considéré
  list(:children, :model=>:animal, :conditions=>{:mother_id=>['session[:current_animal_id]']}, :order=>"born_on DESC") do |t|
    t.column :name, :url=>true
    t.column :born_on
    t.column :sex
    t.column :comment
  end

  # Show one animals with params_id
  def show
    respond_to do |format|
      return unless @animal = find_and_check(:animal)
      format.html do
        session[:current_animal_id] = @animal.id
        t3e @animal
      end
      format.json { render json: @animal }
      format.xml { render xml: @animal }
      format.pdf {
        send_data render_to_string, filename: "animal#{@animal.id}.pdf",
                                    type: 'application/pdf',
                                    disposition: 'inline'
      }
    end
  end

  def render_animals_list(animals)
    report = ThinReports::Report.new layout: File.join(Rails.root, 'app', 'reports', 'animals.tlf')

    animals.each do |animal|
      report.list.add_row do |row|
        row.values no: animal.id,
                   name: animal.name
      end
    end

    send_data report.generate, filename: 'animals.pdf',
                               type: 'application/pdf',
                               disposition: 'attachment'
  end


end
