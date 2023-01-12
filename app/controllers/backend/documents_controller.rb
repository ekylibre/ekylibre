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
      t.column :ocr_presence, datatype: :boolean, class: "center-align"
      t.column :number, url: true
      t.column :name, url: true
      t.column :nature
      t.column :attachement_presence, datatype: :boolean, class: "center-align", hidden: true
      t.column :created_at
      t.column :file_updated_at, url: { format: :pdf }
      t.column :template, url: true
      t.column :file_pages_count, class: "center-align"
      t.column :file_size, class: "center-align"
      t.column :file_content_text, hidden: true
      t.column :file_fingerprint, hidden: true
    end

    def create
      if params[:document][:file]&.content_type&.match(/image/) || (params[:document][:file]&.size || 0) > 300_000
        file_params = { path: permitted_params[:file].tempfile.path, filename: permitted_params[:file].original_filename, content_type: permitted_params[:file].content_type }
        File.open(permitted_params[:file].tempfile.path)
        document_params = permitted_params.to_h.except(:file)
        ImageDocumentCreationJob.perform_later(document_params, file_params, current_user.id)
        notify_success(:document_in_preparation)
        redirect_to backend_documents_path
      else
        @document = resource_model.new(permitted_params)
        return if save_and_redirect(@document, url: (params[:create_and_continue] ? { action: :new, continue: true } : (params[:redirect] || { action: :show, id: 'id'.c })), notify: ((params[:create_and_continue] || params[:redirect]) ? :record_x_created : false), identifier: :name)

        render(locals: { cancel_url: { action: :index }, with_continue: false })
      end
    end

    def show
      return unless @document = find_and_check

      @file_format = case @document.file_content_type
                     when 'application/xml'
                       :xml
                     when 'text/plain'
                       :text
                     when 'application/vnd.oasis.opendocument.spreadsheet'
                       :ods
                     when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                       :xlsx
                     when 'application/zip'
                       :zip
                     else
                       :pdf
                     end

      respond_to do |format|
        format.html { t3e @document }
        format.json
        format.xlsx { send_data(File.read(@document.file.path), type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename: @document.file_file_name) }
        format.ods { send_data(File.read(@document.file.path), type: 'application/vnd.oasis.opendocument.spreadsheet', filename: @document.file_file_name) }
        format.xml { send_data(File.read(@document.file.path), type: 'application/xml', filename: @document.file_file_name) }
        format.text { send_data(File.read(@document.file.path), type: 'text/plain', filename: @document.file_file_name) }
        format.pdf { send_file(@document.file.path(params[:format] != :default ? :original : :default), disposition: 'inline', filename: @document.file_file_name) }
        format.jpg { send_file(@document.file.path(:thumbnail), disposition: 'inline') }
        format.zip { send_file(@document.file.path, type: 'application/zip', filename: @document.name) }
      end
    end

    def purchase_scan
      return unless @document = Document.find(params[:id])

      # launch OCR to create metadata if does not exist
      # or show error
      unless @document.klippa_metadata.present?
        p = PurchaseInvoices::SaisigoOcr.new.post_document_and_parse(@document)
        if p[:status] != :success
          notify(p[:message], p[:status])
          redirect_to params[:redirect] || { action: :show, id: @document.id }
        end
      end
      # launch Parser on metadata to create purchase
      if @document.attach_to_resource && @document.klippa_metadata.present?
        purchase_id = @document.attach_to_resource
        notify :already_transform_purchase_document
        redirect_to backend_purchase_invoice_path(id: purchase_id)
      elsif @document.klippa_metadata.present?
        klippa_parser = PurchaseInvoices::SaisigoParser.new(@document.id)
        new_purchase_id = klippa_parser.parse_and_create_invoice
        if new_purchase_id
          redirect_to backend_purchase_invoice_path(id: new_purchase_id)
        else
          notify_error :cannot_transform_purchase_document
          redirect_to params[:redirect] || { action: :show, id: @document.id }
        end
      end
    end

  end
end
