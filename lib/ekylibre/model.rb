module Ekylibre
  module Model
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model

      def attributes=(**attrs)
        attrs.each do |k, v|
          self.public_send :"#{k}=", v
        end
      end
    end

  end
end
