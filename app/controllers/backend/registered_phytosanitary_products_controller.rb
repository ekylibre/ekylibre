module Backend
  class RegisteredPhytosanitaryProductsController < Backend::BaseController
    unroll :france_maaid, :name

    def get_products_infos
      infos = FormObjects::Backend::RegisteredPhytosanitaryProducts::GetProductsInfo.from_params(params)

      respond_to do |format|
        format.json do
          prods_usages = infos.products_and_usages

          if prods_usages.empty?
            render json: {}
          else
            validator = ::Interventions::Phytosanitary::ValidatorCollectionValidator.build(
              infos.targets_and_shape,
              intervention_to_ignore: infos.intervention,
              intervention_started_at: infos.intervention_started_at,
              intervention_stopped_at: infos.intervention_stopped_at
            )
            result = validator.validate(prods_usages)

            products_infos = prods_usages.map do |pu|
              messages = result.product_grouped_messages(pu.product)
              check_conditions = result.product_messages(pu.product).empty? && pu.usage&.usage_conditions

              [pu.product.id, {
                state: result.product_vote(pu.product),
                allowed_mentions: fetch_allowed_mentions(pu.phyto),
                messages: messages,
                check_conditions: check_conditions
              }]
            end.to_h

            render json: products_infos
          end
        end
      end
    end

    private

      def fetch_allowed_mentions(phyto)
        if phyto.present? && phyto.allowed_mentions.present?
          phyto.allowed_mentions.keys.map { |m| m.parameterize.dasherize }
        else
          []
        end
      end
  end
end
