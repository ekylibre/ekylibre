# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :tenant

    def connect
      self.tenant = request.subdomains.first
      Apartment::Tenant.switch!(tenant)
      puts "Cable verified_user : #{find_verified_user}, tenant : #{self.tenant}"
      self.current_user = find_verified_user
    end

    private

      def find_verified_user
        env['warden'].session_serializer.fetch('user') || reject_unauthorized_connection
      end
  end
end
