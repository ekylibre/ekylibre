module Api
  module V2
    class VariantsController < Api::V2::BaseController
      # GET /api/v2/variants
      # Lists product nature variants (catalog items).
      #
      # Authentication: required.
      #
      # Query string params:
      # - modified_since [ISO8601 date, optional] Returns only variants updated after this date
      #
      # Responses:
      # - 200 OK         Array of variants (Jbuilder template)
      # - 400 Bad Request When `modified_since` is invalid
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
        render 'api/v2/variants/index', locals: { variants: variants }
      end
    end
  end
end
