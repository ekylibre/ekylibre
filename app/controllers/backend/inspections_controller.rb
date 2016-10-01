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
  class InspectionsController < Backend::BaseController
    include InspectionViewable

    manage_restfully sampled_at: 'Time.zone.now'.c

    unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.action :export, on: :both
      t.column :number, url: true
      t.column :activity, url: true
      t.column :product, url: true
      t.column :sampled_at, datatype: :datetime
      # t.column :implanter_rows_number
      # t.column :implanter_working_width
    end

    def export
      inspections = find_inspections
      respond_to do |format|
        format.html
        format.ods do
          send_data(
            inspections_to_ods_export(inspections).bytes,
            filename: "[#{Time.zone.now.l}] #{Inspection.model_name.human}.ods".underscore
          )
        end
      end
    end

    private

    def find_inspections
      inspection_ids = params[:id].split(',')
      inspections = Inspection.where(id: inspection_ids)
      unless inspections.any?
        notify_error :no_inspections_given
        redirect_to(params[:redirect] || { action: :index })
        return nil
      end
      inspections
    end

    # FIXME
    # Not satisfied that the code is here instead of somewhere else but I can't
    # really figure out where it should be.
    #
    # Maybe an Exporter ? A Presenter ? Something along those lines ?
    def inspections_to_ods_export(inspections)
      require 'odf/spreadsheet'
      # HACK: To have the details_hash...
      # that part needs to be reorganized. #TODO
      helper = Object.new.extend(InspectionsHelper)
      output = ODF::Spreadsheet.new
      output.instance_eval do
        office_style :important, family: :cell do
          property :text, 'font-weight': :bold, 'font-size': '11px'
        end
        office_style :bold, family: :cell do
          property :text, 'font-weight': :bold
        end
        inspections.reorder(:activity_id, :sampled_at).each do |inspection|
          table inspection.number do
            row do
              cell "#{Inspection.model_name.human} #{inspection.number}", span: 11, style: :important
            end

            row do
              cell "#{Inspection.human_attribute_name(:activity)}: #{inspection.activity.name}", style: :important, span: 3
              cell
              cell "#{Inspection.human_attribute_name(:product)}: #{inspection.product.name}", style: :important, span: 3
              cell
              cell "#{Inspection.human_attribute_name(:sampled_at)}: #{inspection.sampled_at}", style: :important, span: 3
            end


            hash = helper.data_to_details_hash(inspection)
            hash.each do |title, table|
              row
              row do
                title_colspan = table.map { |_title, contents| contents[:colspan] }.sum
                cell (title.is_a?(Hash) ? title[:title] : title), span: title_colspan, style: :important
              end

              row do
                table.map do |subtitle, contents|
                  cell (subtitle.is_a?(Hash) ? subtitle[:title] : subtitle), style: :important, span: contents[:colspan]
                end
              end

              [:body, :subtotal, :total].each do |part|
                table
                  .values
                  .map { |content| content[part] && content[part].map { |col| col.merge(colspan: content[:colspan]) } }
                  .compact
                  .transpose
                  .map do |i_row|
                    row do
                      i_row.each do |col|
                        style = :bold if [:total, :subtotal].include? part
                        style = :important if col[:tag] == :th
                        cell (col[:content] || '-'), span: col[:colspan], style: style
                      end
                    end
                  end
              end
            end
          end
        end
      end
      output
    end
  end
end
