module Backend
  class RegisteredPhytosanitaryProductsController < Backend::BaseController
    unroll :france_maaid, :name

    def get_products_infos
      respond_to do |format|
        format.json do
          return render json: {} unless params[:products_ids]

          products = Product.where(id: params[:products_ids])
          products_infos = params[:products_ids].map { |id| [id, { state: 'allowed', messages: [], allowed_mentions: [] }] }.to_h

          check_allowed_mentions(products, products_infos)
          check_mix_category_codes(products, products_infos)
          check_organic_mentions(products, products_infos, params[:targets_ids]) if params[:targets_ids]
          check_aquatic_buffer(products, products_infos, params[:usages_ids]) if params[:usages_ids]

          render json: products_infos
        end
      end
    end

    private

      def check_allowed_mentions(products, products_infos)
        products.each do |product|
          next unless (phyto = product.variant.phytosanitary_product) && phyto.allowed_mentions
          phyto.allowed_mentions.keys.each do |key|
            products_infos[product.id.to_s][:allowed_mentions] << key.parameterize.dasherize
          end
        end
      end

      def check_organic_mentions(products, products_infos, targets_ids)
        activities = Product.where(id: targets_ids).map(&:activity).compact.uniq
        return if activities.none?(&:organic_farming?)
        products.each do |product|
          next unless phyto = product.variant.phytosanitary_product
          unless phyto.allowed_for_organic_farming?
            products_infos[product.id.to_s][:messages] << :not_allowed_for_organic_farming.tl
            products_infos[product.id.to_s][:state] = 'forbidden'
          end
        end
      end

      def check_aquatic_buffer(products, products_infos, usages_ids)
        return if products.length == 1
        usages = RegisteredPhytosanitaryUsage.where(id: usages_ids)
        usages.each do |usage|
          if usage.untreated_buffer_aquatic && usage.untreated_buffer_aquatic >= 100
            products.each do |product|
              products_infos[product.id.to_s][:messages] << :substances_mixing_not_allowed_due_to_znt_buffer.tl(usage: usage.crop_label_fra, phyto: usage.product.name)
              products_infos[product.id.to_s][:state] = 'forbidden'
            end
          end
        end
      end

      def check_mix_category_codes(products, products_infos)
        return if products.length == 1
        products.each do |product|
          next unless (phyto = product.variant.phytosanitary_product) && %w[2 3 4 5].include?(phyto.mix_category_code)

          if phyto.mix_category_code == '5'
            products.each do |prod|
              next if prod.id == product.id
              products_infos[prod.id.to_s][:messages] << :cannot_be_mixed_with.tl(phyto: phyto.name)
              products_infos[prod.id.to_s][:state] = 'forbidden'
            end
            products_infos[product.id.to_s][:messages] << :cannot_be_mixed_with_any_product.tl
            products_infos[product.id.to_s][:state] = 'forbidden'

          else
            products.each do |prod|
              next if prod.id == product.id || !(prod_phyto = prod.variant.phytosanitary_product)
              if prod_phyto.mix_category_code == phyto.mix_category_code
                products_infos[product.id.to_s][:messages] << :cannot_be_mixed_with.tl(phyto: prod_phyto.name)
                products_infos[product.id.to_s][:state] = 'forbidden'
              end
            end
          end
        end
      end
  end
end
