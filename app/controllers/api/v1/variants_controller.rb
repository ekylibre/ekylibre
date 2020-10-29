module Api
  module V1
    class VariantsController < Api::V1::BaseController
      def index
        if modified_since = params[:modified_since]
          variants = begin
            date = modified_since.to_date
            ProductNatureVariant.where('updated_at > ?', date).includes(:nature)

          rescue StandardError
            nil
          end
          return error_message('You should provide variants') if variants.nil?
        else
          variants = ProductNatureVariant.all.includes(:nature)
        end
        render 'api/v1/variants/index.json', locals: {variants: variants }
      end
    end
  end
end
