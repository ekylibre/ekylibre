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
            merger = ::Interventions::Phytosanitary::ProductUsageMerger.build(area: shapes_area(infos.shapes))
            merge_success, merge_errors = merger.merge(prods_usages).partition(&:success?)

            validator = ::Interventions::Phytosanitary::ValidatorCollectionValidator.build(
              infos.targets_and_shape,
              intervention_to_ignore: infos.intervention,
              intervention_started_at: infos.intervention_started_at,
              intervention_stopped_at: infos.intervention_stopped_at
            )
            result = merge_error_result(merge_errors)
                       .merge(validator.validate(merge_success.map(&:value)))

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

      def merge_error_result(merge_errors)
        result = ::Interventions::Phytosanitary::Models::ProductApplicationResult.new

        merge_errors.each { |me| result.add_maaid_vote(me.maaid, status: me.vote, message: me.message) }

        result
      end

      # @param [Array<Charta::Geometry>] shapes
      # @return [Maybe<Measure<area>>]
      def shapes_area(shapes)
        area = shapes.reduce(0.in(:hectare)) { |acc, shape| acc + shape.area.in(:square_meter) }

        if area.zero?
          None()
        else
          Some(area)
        end
      end

      def fetch_allowed_mentions(phyto)
        if phyto.present? && phyto.allowed_mentions.present?
          phyto.allowed_mentions.keys.map { |m| m.parameterize.dasherize }
        else
          []
        end
      end
  end
end
