# frozen_string_literal: true

class Reception
  module Transitions
    class Give < Transitionable::Transition
      event :give
      from :draft
      to :given

      attr_reader :given_at

      def initialize(reception, given_at: nil, **options)
        super(reception, **options)

        @given_at = reception.given_at || given_at
      end

      def transition
        resource.transaction do
          resource.given_at = given_at

          resource.items.each do |item|
            explain(:item_creation, name: item.name) { give_item! item }
          end

          resource.state = :given

          resource.save!
        end
      end

      def can_run?
        super && resource.valid? && resource.giveable?
      end

      protected

        def give_item!(item)
          fusing = item.merge_stock? && !item.product_is_unitary?

          # Create a matter for each storing
          item.storings.each do |storing|
            if fusing
              if (product = existing_reception_product_in_storage(storing, item.variant))
                delta = storing.conditioning_quantity
              elsif (product = existing_reception_product_with_default_unit_in_storage(storing, item.variant))
                delta = storing.conditioning_unit.coefficient * storing.conditioning_quantity
              elsif (product = existing_product_in_storage(storing, item.variant))
                products = Product.where(variant: item.variant).select do |p|
                  p.container == storing.storage
                end
                product = item.variant.create_product(product_params(item.variant.default_unit, item))
                delta = products.sum do |p|
                  p.population * p.conditioning_unit.coefficient
                end
                delta += storing.conditioning_quantity * storing.conditioning_unit.coefficient
                if !(catalog_item = CatalogItem.of_variant(item.variant).of_unit(item.variant.default_unit_id).of_usage(:cost).first)
                  if (price_attributes = merged_matters_price_attributes(products)).present?
                    product.variant.catalog_items.create!(price_attributes)
                  end
                end
                products.each do |p|
                  p.update!(dead_at: Time.now)
                end
              end
            end
            if product.nil?
              product = item.variant.create_product(product_params(storing.conditioning_unit_id, item))
              delta = storing.conditioning_quantity
            end
            storing.update(product: product)
            return false, product.errors if product.errors.any?

            ProductMovement.create!(product: product, delta: delta, started_at: given_at, originator: item) unless item.product_is_unitary?
            ProductLocalization.create!(product: product, nature: :interior, container: storing.storage, started_at: given_at, originator: item)
            ProductEnjoyment.create!(product: product, enjoyer: Entity.of_company, nature: :own, started_at: given_at, originator: item)
            ProductOwnership.create!(product: product, owner: Entity.of_company, nature: :own, started_at: given_at, originator: item)
          end
        end

        def default_product_name(item)
          "#{item.variant.name} (#{item.reception.number})"
        end

        def existing_reception_product_with_default_unit_in_storage(storing, variant)
          similar_products = Product.where(variant: variant, conditioning_unit: variant.default_unit)

          similar_products.find do |p|
            location = p.localizations.last.container
            owner = p.owner
            location == storing.storage && owner == Entity.of_company
          end
        end

        def existing_product_in_storage(storing, variant)
          similar_products = Product.where(variant: variant)

          similar_products.find do |p|
            location = p.localizations.last.container
            owner = p.owner
            location == storing.storage && owner == Entity.of_company
          end
        end

        def existing_reception_product_in_storage(storing, variant)
          similar_products = Product.where(variant: variant, conditioning_unit: storing.conditioning_unit)

          similar_products.find do |p|
            location = p.localizations.last.container
            owner = p.owner
            location == storing.storage && owner == Entity.of_company
          end
        end

        def product_params(new_conditioning_id, item)
          {
            name: item.product_name.presence || default_product_name(item),
            identification_number: item.product_identification_number,
            work_number: item.product_work_number,
            initial_born_at: given_at,
            conditioning_unit_id: new_conditioning_id
          }
        end

        def merged_matters_price_attributes(matters)
          with_cost_matters = matters.reject do |matter|
            matter.variant.catalog_items.of_usage(:cost).of_unit(matter.conditioning_unit).empty?
          end
          if with_cost_matters.present?
            begin
              amount = with_cost_matters.sum do |matter|
                unit_price = matter.variant.catalog_items.of_usage(:cost).of_unit(matter.conditioning_unit).first.uncoefficiented_amount
                matter.population * matter.conditioning_unit.coefficient * unit_price
              end
              amount /= with_cost_matters.sum(&:default_unit_population)
              attributes = {
                catalog: Catalog.find_by(usage: :cost),
                all_taxes_included: false,
                amount: amount.round(2),
                unit: matters.first.variant.default_unit,
                started_at: matters.map(&:born_at).min,
                currency: Preference.get(:currency).value
              }
            rescue
              return nil
            end
          end
        end

    end
  end
end
