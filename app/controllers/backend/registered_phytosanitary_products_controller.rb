module Backend
  class RegisteredPhytosanitaryProductsController < Backend::BaseController
    unroll :france_maaid, :name

    def get_products_infos
      infos = FormObjects::Backend::RegisteredPhytosanitaryProducts::GetProductsInfo.from_params(params)

      respond_to do |format|
        format.json do
          targets = infos.targets
          prods_usages = infos.products_and_usages

          if prods_usages.empty?
            render json: {}
          else
            validator = ::Interventions::Phytosanitary::ValidatorCollectionValidator.new(
              ::Interventions::Phytosanitary::MixCategoryCodeValidator.new,
              ::Interventions::Phytosanitary::AquaticBufferValidator.new,
              ::Interventions::Phytosanitary::ProductStateValidator.new,
              ::Interventions::Phytosanitary::OrganicMentionsValidator.new(targets)
            )
            result = validator.validate(prods_usages)

            products_infos = prods_usages.map do |pu|
              messages = result.messages.fetch(pu.product, [])
              state = messages.empty? ? :allowed : :forbidden
              check_conditions = messages.empty? && pu.usage&.usage_conditions

              [pu.product.id, { state: state, allowed_mentions: fetch_allowed_mentions(pu.product), messages: messages, check_conditions: check_conditions }]
            end.to_h

            render json: products_infos
          end
        end
      end
    end

    private

      def fetch_allowed_mentions(product)
        phyto = product.variant.phytosanitary_product

        if phyto.present? && phyto.allowed_mentions.present?
          phyto.allowed_mentions.keys.map { |m| m.parameterize.dasherize }
        else
          []
        end
      end
  end
end
