# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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
  class IssuesController < Backend::BaseController
    manage_restfully t3e: { name: :name, nature: 'RECORD.nature.text'.c }, observed_at: 'Time.zone.now'.c
    manage_restfully_picture

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    list do |t|
      t.action :edit
      t.action :new, url: { controller: :interventions, issue_id: 'RECORD.id'.c, id: nil }
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :nature
      t.column :observed_at
      t.status
      t.column :gravity,  hidden: true
      t.column :priority, hidden: true
    end

    list(:interventions, conditions: { nature: :record, issue_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
      t.column :reference_name, label_method: :name, url: true
      t.column :human_target_names, hidden: true
      t.column :started_at
      t.column :stopped_at, hidden: true
      t.column :actions, hidden: true
      t.status
    end

    def new
      # Taken almost-verbatim from manage_restully-generated code
      options = {
        custom_fields: params[:custom_fields],
        dead: params[:dead],
        description: params[:description],
        geolocation: params[:geolocation],
        gravity: params[:gravity],
        name: params[:name],
        nature: params[:nature],
        observed_at: Time.zone.now,
        picture_content_type: params[:picture_content_type],
        picture_file_name: params[:picture_file_name],
        picture_file_size: params[:picture_file_size],
        picture_updated_at: params[:picture_updated_at],
        priority: params[:priority],
        state: params[:state],
        target_id: params[:target_id],
        target_type: params[:target_type]
      }

      if params[:lat].present? && params[:lon].present?
        geolocation = ::Charta.new_point(params[:lat], params[:lon])
        options[:geolocation] = geolocation
      end

      @issue = Issue.new(options)

      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    def close
      return unless @issue = find_and_check

      @issue.close if @issue.can_close?
      redirect_to_back
    end

    def abort
      return unless @issue = find_and_check

      @issue.abort if @issue.can_abort?
      redirect_to_back
    end

    def reopen
      return unless @issue = find_and_check

      @issue.reopen if @issue.can_reopen?
      redirect_to_back
    end
  end
end
