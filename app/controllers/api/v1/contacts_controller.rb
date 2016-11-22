module Api
  module V1
    # Contacts API permits to access contacts
    class ContactsController < Api::V1::BaseController

      def index
        @contacts = Entity.includes(direct_links: :linked)
      end

      def picture

        return unless contact = Entity.find_by(id: params[:contact_id])
        if contact.picture.file?

          unless File.exist?(contact.picture.path(:contact))
            contact.picture.reprocess! :contact
          end

          f = File.read(contact.picture.path(:contact))
          render json: { picture: Base64::strict_encode64(f) }
        else
          head :not_found
        end
      end
    end
  end
end
