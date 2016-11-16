module Api
  module V1
    # Contacts API permits to access contacts
    class ContactsController < Api::V1::BaseController
      def index
        @contacts = Entity.contacts

      end
    end
  end
end
