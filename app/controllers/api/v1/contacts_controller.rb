module Api
  module V1
    # Contacts API permits to access contacts
    class ContactsController < Api::V1::BaseController
      def index
        @contacts = Entity.includes(direct_links: :linked)
      end
    end
  end
end
