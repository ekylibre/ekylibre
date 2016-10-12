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
  class ListingsController < Backend::BaseController
    unroll

    list(order: :name) do |t|
      t.action :extract, url: { format: :csv }, image: :action
      # t.action :extract, url: {format: :csv, mode: :no_mail}, if: :can_mail?, image: :nomail
      # t.action :mail, if: :can_mail?
      t.action :duplicate, method: :post
      t.action :edit
      t.action :destroy
      t.action :new, on: :none
      t.column :name, url: { action: :edit }
      t.column :root_model_name
      t.column :description
    end

    # Displays the main page with the list of listings
    def index
      session[:listing_coordinate_column] = nil
    end

    def extract
      return unless @listing = find_and_check
      begin
        @listing.save unless @listing.query?
        query = @listing.query.to_s
        # FIXME: This is dirty code to solve quickly no_mail mode
        query.gsub!(' ORDER BY ', ' AND (' + @listing.coordinate_columns.collect { |c| "#{c.name} NOT LIKE '%@%.%'" }.join(' AND ') + ') ORDER BY ') if params[:mode] == 'no_mail'
        # FIXME: Manage suppression of CURRENT_COMPANY...
        first_item = []
        @listing.exportable_fields.each { |item| first_item << item.label }
        result = ActiveRecord::Base.connection.select_rows(query)
        result.insert(0, first_item)

        respond_to do |format|
          format.xml { render xml: result.to_xml, filename: @listing.name.simpleize + '.xml' }
          format.csv do
            csv_string = Ekylibre::CSV.generate do |csv|
              for item in result
                csv << item
              end
            end
            send_data(csv_string, filename: @listing.name.simpleize + '.csv', type: Mime::CSV)
          end
        end

      rescue Exception => e
        notify_error(:fails_to_extract_listing, message: e.message)
        redirect_to_back
      end
    end

    def new
      @listing = Listing.new root_model: params[:root_model], name: params[:name]
      # render_restfully_form
    end

    def create
      @listing = Listing.new permitted_params
      return if save_and_redirect(@listing, url: { action: :edit, id: 'id'.c })
      # render_restfully_form
    end

    def edit
      return unless @listing = find_and_check
      t3e @listing.attributes
      # render_restfully_form
    end

    def update
      return unless @listing = find_and_check
      @listing.attributes = permitted_params
      return if save_and_redirect(@listing, url: { action: :edit, id: 'id'.c })
      t3e @listing.attributes
      # render_restfully_form
    end

    def destroy
      return unless @listing = find_and_check
      Listing.destroy(@listing.id) if @listing
      redirect_to action: :index
    end

    def duplicate
      return unless @listing = find_and_check
      @listing.duplicate
      redirect_to action: :index
    end

    def mail
      return unless @listing = find_and_check
      if (query = @listing.query).blank?
        @listing.save
        query = @listing.query
      end
      query = query.to_s
      if !@listing.can_mail? || query.blank?
        notify_warning(:you_must_have_an_email_column)
        redirect_to_back
        return
      end
      if session[:listing_coordinate_column] || @listing.coordinate_columns.count == 1
        full_results = ActiveRecord::Base.connection.select_all(query)
        listing_coordinate_column = @listing.coordinate_columns.count == 1 ? @listing.coordinate_columns[0] : find_and_check(:listing_node, session[:listing_coordinate_column])
        # raise StandardError.new listing_coordinate_column.inspect
        results = full_results.select { |c| !c[listing_coordinate_column.label].blank? }
        @mails = results.collect { |c| c[listing_coordinate_column.label] }
        # @mails.uniq! ### CHECK ????????
        @columns = (!full_results.empty? ? full_results[0].keys.sort : [])
        session[:mail] ||= {}
      end
      if request.post?
        if params[:node]
          session[:listing_coordinate_column] = ListingNode.find_by_key(params[:node][:mail]).id
          redirect_to_back
        else
          session[:mail] = params.dup
          session[:mail].delete(:attachment)
          texts = [params[:mail_subject], params[:mail_body]]
          if attachment = (params[:attachment].blank? ? nil : params[:attachment])
            # file = "#{Rails.root.to_s}/tmp/uploads/attachment_#{attachment.original_filename.gsub(/\W/,'_')}"
            # File.open(file, "wb") { |f| f.write(attachment.read)}
            attachment = { filename: attachment.original_filename, content_type: attachment.content_type, body: attachment.read.dup }
          end
          if params[:send_test]
            results = [results[0]]
            results[0][listing_coordinate_column.label] = params[:from]
          end
          for result in results
            ts = texts.collect do |t|
              r = t.to_s.dup
              @columns.each { |c| r.gsub!(/\{\{#{c}\}\}/, result[c].to_s) }
              r
            end
            Mailman.mailing(params[:from], result[listing_coordinate_column.label], ts[0], ts[1], attachment).deliver
          end
          notify_success_now(:mails_are_sent)
          session[:listing_coordinate_column] = nil
        end
      end
      t3e @listing.attributes
    end

    protected

    def permitted_params
      params.require(:listing).permit!
    end
  end
end
