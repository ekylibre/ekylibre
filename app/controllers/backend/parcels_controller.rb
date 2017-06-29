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
  class ParcelsController < Backend::BaseController
    # Displays the main page with the list of parcels
    def index
      respond_to do |format|
        format.html
        format.xml { render xml: @parcels }
        format.pdf { render pdf: @parcels, with: params[:template] }
      end
    end

    # Displays details of one parcel selected with +params[:id]+
    def show
      return unless (@parcel = find_and_check)
      respond_with(@parcel, methods: %i[all_item_prepared status items_quantity],
                            include: { address: { methods: [:mail_coordinate] },
                                       sale: {},
                                       purchase: {},
                                       recipient: {},
                                       sender: {},
                                       transporter: {},
                                       items: { methods: %i[status prepared], include: %i[product variant] } }) do |format|
        format.html do
          t3e @parcel.attributes.merge(nature: @parcel.nature.text)
        end
      end
    end

    before_action only: :new do
      params[:nature] ||= 'incoming'
    end

    def new
      columns = Parcel.columns_definition.keys
      columns = columns.delete_if { |c| %i[depth rgt lft id lock_version updated_at updater_id creator_id created_at].include?(c.to_sym) }
      values = columns.map(&:to_sym).uniq.each_with_object({}) do |attr, hash|
        hash[attr] = params[:"#{attr}"] unless attr.blank? || attr.to_s.match(/_attributes$/)
        hash
      end
      values[:planned_at] ||= Time.zone.now

      @parcel = Parcel.new(values)

      if params[:sale_id]
        sale = Sale.find(params[:sale_id])
        @parcel.recipient = sale.client
        @parcel.address = sale.delivery_address

        sale.items.each do |item|
          item.variant.take(item.quantity).each do |product, quantity|
            @parcel.items.new(sale_item_id: item.id, source_product: product, quantity: quantity)
          end
        end
      end

      if params[:purchase_id]
        purchase = Purchase.find(params[:purchase_id])
        @parcel.sender = purchase.supplier
        @parcel.address = purchase.delivery_address
        preceding = Parcel
                    .where(nature: @parcel.nature, sender: @parcel.sender)
                    .order(planned_at: :desc).first
        @parcel.storage = preceding.storage if preceding

        purchase.items.each do |item|
          @parcel.items.new(purchase_item_id: item.id, quantity: item.quantity, variant: item.variant)
        end
      end
      t3e(@parcel.attributes.merge(nature: @parcel.nature.text))
      render locals: { with_continue: true }
    end

    # Converts parcel to trade
    def invoice
      parcels = find_parcels
      return unless parcels
      parcel = parcels.first
      if parcels.all? { |p| p.incoming? && p.third_id == parcel.third_id && p.invoiceable? }
        purchase = Parcel.convert_to_purchase(parcels)
        redirect_to backend_purchase_path(purchase)
      elsif parcels.all? { |p| p.outgoing? && p.third_id == parcel.third_id && p.invoiceable? }
        sale = Parcel.convert_to_sale(parcels)
        redirect_to backend_sale_path(sale)
      else
        notify_error(:all_parcels_must_be_invoiceable_and_of_same_nature_and_third)
        redirect_to(params[:redirect] || { action: :index })
      end
    end

    # Pre-fill delivery form with given parcels. Nothing else.
    # Only a shortcut now.
    def ship
      parcels = find_parcels
      return unless parcels
      parcel = parcels.detect(&:shippable?)
      options = { parcel_ids: parcels.map(&:id) }
      if !parcel
        redirect_to(options.merge(controller: :deliveries, action: :new))
      elsif parcels.all? { |p| p.shippable? && (p.delivery_mode == parcel.delivery_mode) }
        options[:mode] = parcel.delivery_mode
        options[:transporter_id] = parcel.transporter_id if parcel.transporter
        redirect_to(options.merge(controller: :deliveries, action: :new))
      else
        notify_error(:some_parcels_are_not_shippable)
        redirect_to(params[:redirect] || { action: :index })
      end
    end

    Parcel.state_machine.events.each do |event|
      define_method event.name do
        fire_event(event.name)
      end
    end

    protected

    def find_parcels
      parcel_ids = params[:id].split(',')
      parcels = parcel_ids.map { |id| Parcel.find_by(id: id) }.compact
      unless parcels.any?
        notify_error :no_parcels_given
        redirect_to(params[:redirect] || { action: :index })
        return nil
      end
      parcels
    end
  end
end
