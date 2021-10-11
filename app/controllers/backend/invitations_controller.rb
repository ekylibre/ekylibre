# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class InvitationsController < Backend::BaseController
    list(model: :users,
         conditions: ["#{User.table_name}.invitation_created_at IS NOT NULL"],
         order: 'users.last_name') do |t|
      t.action :destroy, if: 'RECORD.invitation_accepted_at.nil?'.c
      t.column :first_name
      t.column :last_name
      t.column :email
      t.column :role, url: true
      t.column :invitation_status, label: :invitation_status
    end

    def index; end

    def new
      @invitation = FormObjects::Backend::Invitation.with_defaults

      @form_url = backend_invitations_path
    end

    def create
      @invitation = FormObjects::Backend::Invitation.with_defaults
      @invitation.attributes = invite_params

      if @invitation.valid?
        User.invite!(@invitation.attributes, current_user)

        redirect_to backend_invitations_path
      else
        @form_url = backend_invitations_path
        render :new
      end
    end

    private

      def invite_params
        params.require(:form_objects_backend_invitation)
              .permit(:first_name, :last_name, :language, :role_id, :email)
              .symbolize_keys
      end
  end
end
