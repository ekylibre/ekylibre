# rubocop:disable Security/Eval, Lint/UnusedBlockArgument

require 'rodf'

module Printers
  class ListPrinter

    def initialize(file_name:, query:, content:)
      @file_name = file_name
      @query = query
      @content = content
    end

    def compute_dataset
      eval(@query)
    end

    def run_ods
      records = compute_dataset
      content = @content
      data = RODF::Spreadsheet.new

      data.instance_eval do
        office_style :head, family: :cell do
          property :text, 'font-weight': :bold
          property :paragraph, 'text-align': :center
        end

        table @file_name do
          row do
            content.keys.each do |header|
              cell header, style: :head
            end
          end

          records.each do |record|
            row do
              content.values.each do |value_code|
                cell eval(value_code)
              end
            end
          end
        end
      end
      data.bytes
    end

    def run_csv(encoding: 'UTF-8', **options)
      records = compute_dataset

      ::CSV.generate(encoding: encoding, **options) do |csv|
        csv << @content.keys
        records.each do |record|
          csv << @content.values.map { |value_code| eval(value_code) }
        end
      end
    end

    def run_xcsv
      run_csv(col_sep: ';')
    end
  end
end

# rubocop:enable Security/Eval, Lint/UnusedBlockArgument
