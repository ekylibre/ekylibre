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
  class DocumentsController < Backend::BaseController
    unroll

    manage_restfully

    # manage_restfully_picture

    # respond_to :html, :json, :xml

    def self.list_conditions
      code = ''
      code = search_conditions(documents: %i[name]) + " ||= []\n"
      
      code << "if params[:created_at].present? && params[:created_at].to_s != 'all'\n"
      code << " c[0] << ' AND #{Document.table_name}.created_at::DATE BETWEEN ? AND ?'\n"
      code << " if params[:created_at].to_s == 'interval'\n"
      code << "   c << params[:created_at_started_on]\n"
      code << "   c << params[:created_at_stopped_on]\n"
      code << " else\n"
      code << "   interval = params[:created_at].to_s.split('_')\n"
      code << "   c << interval.first\n"
      code << "   c << interval.second\n"
      code << " end\n"
      code << "end\n"

      code << "if params[:nature].present?\n"
      code << " c[0] << ' AND #{Document.table_name}.nature = ?'\n"
      code << " c << params[:nature]\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: list_conditions) do |t|
      t.action :destroy, if: :destroyable?
      t.column :mandatory, class: "center-align"
      t.column :number, url: true
      t.column :name, url: true
      t.column :nature
      t.column :created_at
      t.column :file_updated_at, url: { format: :pdf }
      t.column :template, url: true
      t.column :file_pages_count, class: "center-align"
      t.column :file_file_size, class: "center-align"
      t.column :file_content_text, hidden: true
      t.column :file_fingerprint, hidden: true
    end

    def show
      return unless @document = find_and_check
      @file_format = if @document.file_content_type == 'application/xml'
                       :xml
                     elsif @document.file_content_type == 'text/plain'
                       :text
                     else
                       :pdf
                     end

      respond_to do |format|
        format.html { t3e @document }
        format.json
        format.xml { send_data(File.read(@document.file.path), type: 'application/xml', filename: @document.file_file_name) }
        format.text { send_data(File.read(@document.file.path), type: 'text/plain', filename: @document.file_file_name) }
        format.pdf { send_file(@document.file.path(params[:format] != :default ? :original : :default), disposition: 'inline', filename: @document.file_file_name) }
        format.jpg { send_file(@document.file.path(:thumbnail), disposition: 'inline') }
      end
    end
  end
end
