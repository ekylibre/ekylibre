# frozen_string_literal: true

class ParcelToSaleConverter
  attr_reader :parcels, :sale_journals

  def initialize(parcels:, sale_journals: Journal.sales)
    @parcels = parcels.collect{ |p| p.is_a?(Parcel) ? p : Parcel.find(p)}.sort_by(&:first_available_date)
    @sale_journals = sale_journals
  end

  def call
    sale = nil
    ActiveRecord::Base.transaction do
      sale = Sale.new(
        client: third,
        nature: sale_nature,
        delivery_address: parcels.last.address
      )

      parcels.each do |parcel|
        parcel.items.order(:id).each do |item|
          sale_item = ParcelItemToSaleItemBuilder.new(parcel_item: item).call
          next unless sale_item.present?

          sale.items << sale_item
          item.sale_item = sale_item
        end
      end

      if sale.items.any?
        # Refreshes affair
        sale.save!
        parcels.each(&:reload)
        parcels.each { |p| p.update!(sale_id: sale.id) }
      end
    end
    sale.persisted? ? sale : nil
  end

  private

    def sale_nature
      planned_at = parcels.last.first_available_date || Time.zone.now

      if parcels&.last&.sale_nature
        parcels&.last&.sale_nature
      elsif SaleNature.by_default
        SaleNature.by_default
      else
        unless journal = sale_journals.opened_on(planned_at).first
          raise 'No sale journal'
        end

        SaleNature.create!(
          active: true,
          currency: Preference[:currency],
          journal: journal,
          by_default: true,
          name: SaleNature.tc('default.name', default: SaleNature.model_name.human),
          catalog: Catalog.of_usage(:sale).first
        )
      end
    end

    def third
      thirds = parcels.map(&:third_id).uniq
      raise "Need unique third (#{thirds.inspect})" if thirds.count != 1

      Entity.find(thirds.first)
    end

end
