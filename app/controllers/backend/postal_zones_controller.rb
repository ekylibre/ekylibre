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
  class PostalZonesController < Backend::BaseController
    manage_restfully country: 'Preference[:country]'.c

    unroll

    autocomplete_for :name

    list(conditions: search_conditions(postal_zones: [:postal_code, :name]), order: :name) do |t|
      t.action :edit
      t.action :destroy
      t.column :name
      t.column :postal_code
      t.column :city
      t.column :code
      t.column :district, url: true
      t.column :country
    end

    class FlatTable
      attr_accessor :headers, :rows

      def initialize
        @headers = []
        @rows = []
      end

      def self.open(path)
        hash = JSON.parse(File.read(path))
        table = new
        table.headers = hash['headers']
        table.rows = hash['rows']
        table
      end

      def self.parse(string, format)
        table = new
        if format == :csv
          string.encode!('utf-8', 'utf-8')
          rows = CSV.parse(string)
          headers = rows.shift
          table.headers = headers.map do |h|
            { 'name' => h, 'type' => 'string' }
          end
          table.rows = rows
        elsif format == :xcsv
          # string.encode!('utf-8', 'utf-8')
          rows = CSV.parse(string, col_sep: ';', encoding: 'CP1252')
          headers = rows.shift
          table.headers = headers.map do |h|
            { 'name' => h, 'type' => 'string' }
          end
          table.rows = rows
        elsif format == :geojson
          hash = JSON.parse(string)
          if hash.is_a?(Array)
            hash = { 'type' => 'FeatureCollection', 'features' => hash }
          end
          unless %w(Feature FeatureCollection).include?(hash['type'])
            hash = { 'type' => 'Feature', 'geometry' => hash }
          end
          if hash['type'] == 'Feature'
            hash = { 'type' => 'FeatureCollection', 'features' => [hash] }
          end
          headers = [{ 'name' => 'geometry', 'type' => 'geometry' }]
          rows = []
          hash['features'].each do |feature|
            row = [feature['geometry']]
            if feature['properties'].is_a?(Hash)
              feature['properties'].each do |k, v|
                k += '!' if k == 'geometry'
                headers << { 'name' => k, 'type' => 'string' } unless headers.include?(k)
                row[headers.index { |h| h['name'] == k }] = v
              end
            end
            rows << row
          end
          table.headers = headers
          table.rows = rows
        else
          raise "Unknown format: #{format}"
        end
        table
      end

      def to_json
        # raise({ headers: @headers, rows: @rows, created_at: Time.zone.now }.inspect)
        { headers: @headers, rows: @rows, created_at: Time.zone.now }.to_json
      end
    end

    def import
      @step = (params[:step] || 'undefined').to_sym
      if [:select, :upload, :match, :check].include?(@step)
        @tmp = Ekylibre::Tenant.private_directory.join('tmp', 'imports')
        FileUtils.mkdir_p(@tmp)
        send('import_' + @step.to_s)
      else
        redirect_to action: :index
      end
    end

    protected

    def import_select
    end

    def import_upload
      data = params[:upload]
      # raise data.headers.inspect
      table = FlatTable.parse(data.read, params[:format].to_sym)
      file_id = Time.zone.now.to_i.to_s + '-' + rand(1_679_616).to_s(36) + rand(1_679_616).to_s(36) + '-' + params[:format]
      File.write(@tmp.join(file_id), table.to_json)
      redirect_to action: :import, step: :match, file_id: file_id
    end

    def import_match
      file = find_import_file
      return false unless file
      table = FlatTable.open(file)
      @headers = table.headers
      @row = table.rows.first
      @selection = []
      PostalZone.columns.each do |c|
        next if c.type == :boolean ||
                [:id, :lock_version, :created_at, :updated_at].include?(c.name.to_sym) ||
                c.name.to_s =~ /\_(id|type)\z/
        @selection << [PostalZone.human_attribute_name(c.name), "#attr:#{c.name}"]
      end
      PostalZone.reflect_on_all_associations(:belongs_to).each do |r|
        next if [:creator, :updater].include?(r.name)
        next unless PostalZone.instance_methods.include?("#{r.name}_attributes=".to_sym)
        linked = r.class_name.constantize
        linked.columns.each do |c|
          next if c.type == :boolean ||
                  [:id, :lock_version, :created_at, :updated_at].include?(c.name.to_sym) ||
                  c.name.to_s =~ /\_(id|type)\z/
          @selection << [PostalZone.human_attribute_name(r.name) + '/' +
                         linked.human_attribute_name(c.name), "#{r.name}#attr:#{c.name}"]
        end
        if linked.columns_hash['custom_fields']
          @selection << [PostalZone.human_attribute_name(r.name) + '/' +
                         t('.create_custom_field'), "#{r.name}#custom"]
        end
      end
      @selection.sort! { |a, b| a.first <=> b.first }
      if PostalZone.columns_hash['custom_fields']
        @selection << [t('.create_custom_field'), '#custom']
      end
      @selection.insert(0, [t('.not_used'), 'none'])
    end

    def import_check
      file = find_import_file
      return false unless file
      table = FlatTable.open(file)
      @headers = table.headers
      @row = table.rows.first

      @errors = {}
      table.rows.each_with_index do |_row, index|
        begin
          attributes = {}
          PostalZone.create!(attributes)
        rescue ActiveRecord::RecordInvalid => e
          @errors[index + 1] = e
          if @errors.size > 200
            @too_many_errors = true
            break
          end
        end
      end

      if @errors.any?
        params[:step] = 'match'
        import
        return false
      else
        redirect_to action: :index
      end
    end

    def find_import_file
      unless params[:file_id]
        notify_error :please_select_a_file_to_upload
        redirect_to action: :import, step: :select
        return false
      end
      file = @tmp.join(params[:file_id])
      unless file.exist?
        notify_error :please_select_a_file_to_upload
        redirect_to action: :import, step: :select
        return false
      end
      file
    end
  end
end
