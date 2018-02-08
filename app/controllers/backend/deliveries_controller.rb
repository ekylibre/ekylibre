# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class DeliveriesController < Backend::BaseController
    manage_restfully parcel_ids: '(params[:parcel_ids] || [])'.c,
                     reception_ids: '(params[:reception_ids] || [])'.c,
                     shipment_ids: '(params[:shipment_ids] || [])'.c,
                     responsible_id: 'current_user.person.id'.c,
                     started_at: 'Time.zone.now'.c,
                     driver_id: 'current_user.person.id'.c

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

    unroll

    list(conditions: search_conditions(deliveries: %i[number annotation], entities: %i[number full_name])) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :annotation
      t.status
      t.column :mode
      t.column :responsible
      t.column :started_at
      t.column :transporter, label_method: :full_name, url: true
      # t.column :net_mass
    end

    list(:parcels, conditions: { delivery_id: 'params[:id]'.c }, order: :position) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :nature
      t.column :state
      t.status
      # t.column :sender, url: true
      # t.column :recipient, url: true
      # t.column :sale, url: true, hidden: true
      # t.column :purchase, url: true, hidden: true
      # t.column :net_mass
    end

    list(:receptions, conditions: { delivery_id: 'params[:id]'.c }, order: :position) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :state
      t.status
      t.column :sender, url: true
      # t.column :purchase, url: true, hidden: true
      # t.column :net_mass
    end

    list(:shipments, conditions: { delivery_id: 'params[:id]'.c }, order: :position) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :state
      t.status
      t.column :recipient, url: true
      t.column :sale, url: true, hidden: true
      # t.column :net_mass
    end

    # Displays details of one sale selected with +params[:id]+
    def show
      @entity_of_company_picture_path = Entity.of_company.picture_path
      return unless @delivery = find_and_check
      respond_with(@delivery, methods: %i[all_parcels_prepared human_delivery_mode],
                              include: {
                                parcels: {
                                  methods: %i[human_delivery_mode human_delivery_nature],
                                  include: {
                                    items: {
                                      include: %i[variant product]
                                    },
                                    address: {},
                                    sender: {},
                                    recipient: {}
                                  }
                                },
                                transporter: {},
                                responsible: {}
                              }) do |format|
        format.html do
          t3e @delivery.attributes
        end
      end
    end

    Delivery.state_machine.events.each do |event|
      define_method event.name do
        fire_event(event.name)
      end
    end
  end
end
