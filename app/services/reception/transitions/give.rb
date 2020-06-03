class Reception
  module Transitions
    class Give < Transitionable::Transition

      event :give
      from :draft
      to :given

      attr_reader :given_at

      def initialize(reception, given_at: nil, **_options)
        super reception

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

          true
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
            product_params = {
              name: item.product_name.presence || default_product_name(item),
              identification_number: item.product_identification_number,
              work_number: item.product_work_number,
              initial_born_at: given_at
            }

            product = existing_reception_product_in_storage(storing, item.variant) if fusing
            product ||= item.variant.create_product!(product_params)

            storing.update!(product: product)

            ProductMovement.create!(product: product, delta: storing.quantity, started_at: given_at, originator: item) unless item.product_is_unitary?
            ProductLocalization.create!(product: product, nature: :interior, container: storing.storage, started_at: given_at, originator: item)
            ProductEnjoyment.create!(product: product, enjoyer: Entity.of_company, nature: :own, started_at: given_at, originator: item)
            ProductOwnership.create!(product: product, owner: Entity.of_company, nature: :own, started_at: given_at, originator: item)
          end
        end

        def default_product_name(item)
          "#{item.variant.name} (#{item.reception.number})"
        end

        def existing_reception_product_in_storage(storing, variant)
          similar_products = Product.where(variant: variant)

          similar_products.find do |p|
            location = p.localizations.last.container
            owner = p.owner
            location == storing.storage && owner == Entity.of_company
          end
        end

    end
  end
end