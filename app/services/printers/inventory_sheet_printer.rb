# frozen_string_literal: true

module Printers
  class InventorySheetPrinter < PrinterBase
    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # Set Inventory.id as instance variable @id
    #  Set Current inventory as instance variable @inventory
    def initialize(*_args, id:, template:, **_options)
      super(template: template)
      @id = id
      @inventory = Inventory.find_by_id(id)
      @item_undefined_container = @inventory.items.all.select{|b| b.container.present? == false}
    end

    #  Generate document name
    def document_name
      "#{template.nature.human_name} : #{@inventory.name}"
    end

    #  Create document key
    def key
      self.class.build_key(id: @id, updated_at: @inventory.updated_at.to_s)
    end

    def compute_dataset

      #  Create Zones
      zones = BuildingDivision.all.select{|b| b.containeds.any?}.map do |zone|
        products= zone.containeds
        products_items = products.map do |product|
          if product.present?
            item= product.inventory_items.find_by(inventory_id: @id)
            if item.present?
              {
                name: product.name,
                type: product.nature.name,
                actual: item.actual_population,
                expected: item.expected_population,
                unity: product.variant.unit_name,
                unit_value: item.unit_pretax_stock_amount,
                total_value: item.actual_pretax_stock_amount
              }
            end
          end
        end
        products_sorted = products_items.compact.sort_by{|product| product[:type] }
        {
          name: zone.name,
          products: products_sorted
        }
      end

      if @item_undefined_container.any?
        products_items = @item_undefined_container.map do |item|
          {
            name: item.product.name,
            type: item.product.nature.name,
            actual: item.actual_population,
            expected: item.expected_population,
            unity: item.product.variant.unit_name,
            unit_value: item.unit_pretax_stock_amount,
            total_value: item.actual_pretax_stock_amount
          }
        end
        products_sorted = products_items.compact.sort_by{|product| product[:type] }

        zones.append({
          name: :undefined_container.tl,
          products: products_sorted
        })

      end

      {
        zones: zones.any? ? zones : [],
        inventory: @inventory,
        company: Entity.of_company
      }
    end

    def generate(r)
      currency = Onoma::Currency.find(Preference[:currency]).symbol
      dataset = compute_dataset
      r.add_field 'DOCUMENT_NAME', document_name
      # Section-info
      r.add_field 'INVENTORY_NUMBER', @inventory.number
      r.add_field 'INVENTORY_DATE', @inventory.created_at.strftime("%d/%m/%Y")
      r.add_field(:responsible, @inventory.responsible || @inventory.creator.person.full_name)

      # Inside Table-targets
      r.add_section('Section-zone', dataset.fetch(:zones)) do |sz|
        sz.add_field(:building_zone_name) { |zone| zone[:name] }
        sz.add_field(:item_count) {|zone| zone[:products].size}
        sz.add_field(:amount) {|zone| zone[:products].map{|product| product[:total_value]}.sum.round_l << currency}
        sz.add_table('Table_inventory_items', :products, header: true) do |t|
          t.add_field(:item_name) { |product| product[:name] }
          t.add_field(:item_type) { |product| product[:type] }
          t.add_field(:item_quantity_before) { |product| "#{product[:expected]} #{product[:unity]}" }
          t.add_field(:item_quantity_after) { |product| "#{product[:actual]} #{product[:unity]}"}
          t.add_field(:item_unit_cost) { |product| product[:unit_value].round_l << currency }
          t.add_field(:item_total_cost) { |product| product[:total_value].round_l << currency }
        end
      end

      r.add_field(:company_name, dataset.fetch(:company).name)
      r.add_field(:company_address, dataset.fetch(:company).mails.where(by_default: true).first.coordinate)
      r.add_field(:company_siret, dataset.fetch(:company).siret_number)
      r.add_field(:printed_at, Time.zone.now.l(format: '%d/%m/%Y %T'))
    end
  end
end
