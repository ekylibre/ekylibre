module Api
  module V1
    # Contacts API permits to access contacts
    class ContactsController < Api::V1::BaseController
      def index
        last_synchro = begin
                         DateTime.parse(permitted_params[:last_synchro])
                       rescue
                         DateTime.new(1, 1, 1, 1, 1, 1).in_time_zone
                       end

        @items =
          {
            create: Entity.includes(direct_links: :linked).where('created_at >= ?', last_synchro),
            update: Entity.includes(direct_links: :linked).where(id: EntityAddress.unscoped.joins(:entity).where('entities.created_at < ? AND (entity_addresses.deleted_at >= ? OR entity_addresses.updated_at >= ?)', last_synchro, last_synchro, last_synchro).pluck(:entity_id).uniq),
            destroy: Version.destructions.where(item_type: 'Entity').after(last_synchro).select { |v| v.item_object[:created_at].present? && v.item_object[:created_at] < last_synchro }.collect { |v| { item_id: v.item_id } }
          }
      end

      def picture
        return unless contact = Entity.find_by(id: params[:contact_id])
        if contact.picture.file?

          unless File.exist?(contact.picture.path(:contact))
            contact.picture.reprocess! :contact
          end

          f = File.read(contact.picture.path(:contact))
          render json: { picture: Base64.urlsafe_encode64(f) }
        else
          head :not_found
        end
      end

      protected

      def permitted_params
        params.permit(:last_synchro)
      end
    end
  end
end
