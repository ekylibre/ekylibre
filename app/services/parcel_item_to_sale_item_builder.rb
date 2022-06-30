# frozen_string_literal: true

class ParcelItemToSaleItemBuilder
  def initialize(parcel_item: )
    @parcel_item = parcel_item
  end

  def call
    return unless check

    SaleItem.new(
      variant: parcel_item.variant,
      unit_pretax_amount: unit_pretax_amount,
      amount: unit_pretax_amount,
      conditioning_unit: parcel_item.conditioning_unit,
      conditioning_quantity: parcel_item.conditioning_quantity,
      tax: tax,
      shipment_item_id: parcel_item.id,
      quantity: parcel_item.population
    )
  end

  private

    attr_reader :parcel_item

    def tax
      if (last_sale_items = SaleItem.where(variant: parcel_item.variant)).any?
        last_sale_items.order(id: :desc).first.tax
      elsif catalog_item && catalog_item.all_taxes_included
        catalog_item.reference_tax
      else
        parcel_item.variant.category.sale_taxes.first || Tax.current.first
      end
    end

    def unit_pretax_amount
      unit_pretax_amount = parcel_item.unit_pretax_sale_amount&.zero? ? nil : parcel_item.unit_pretax_sale_amount
      return unit_pretax_amount if unit_pretax_amount

      # 1 - from last sale parcel_item
      if (last_sale_items = SaleItem.where(variant: parcel_item.variant)).any?
        unit_pretax_amount ||= last_sale_items.order(id: :desc).first.unit_pretax_amount
      # 2 - from catalog with taxes
      elsif catalog_item && catalog_item.all_taxes_included
        unit_pretax_amount ||= catalog_item.reference_tax.pretax_amount_of(catalog_item.amount)
      # 3 - from catalog without taxes
      elsif catalog_item
        unit_pretax_amount ||= catalog_item.amount
      else
        0.0
      end
    end

    def catalog_item
      @catalog_item ||= Catalog.by_default!(:sale).items.find_by(variant: parcel_item.variant)
    end

    def check
      parcel_item.variant.saleable? && parcel_item.population && parcel_item.population > 0
    end
end
