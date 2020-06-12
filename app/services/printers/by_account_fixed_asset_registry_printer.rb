module Printers
  class ByAccountFixedAssetRegistryPrinter < FixedAssetRegistryPrinter

    def run_pdf
      dataset = compute_dataset
      totals = dataset.totals

      generate_report(@template_path) do |r|
        r.add_field 'COMPANY_ADDRESS', dataset.company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILE_NAME', key
        r.add_field 'STOPPED_ON', @stopped_on.to_date.l
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'TOTAL_AMOUNT', as_currency(totals[:total_amount])
        r.add_field 'TOTAL_DEPRECIABLE_AMOUNT', as_currency(totals[:total_depreciable_amount])
        r.add_field 'TOTAL_DEPRECIATED_AMOUNT', as_currency(totals[:total_depreciated_amount])
        r.add_field 'TOTAL_CURRENT_DEPRECIATION_AMOUNT', as_currency(totals[:total_current_depreciation_amount])
        r.add_field 'TOTAL_CUMULATED_DEPRECIATED_AMOUNT', as_currency(totals[:total_cumulated_depreciated_amount])
        r.add_field 'TOTAL_NET_BOOK_VALUE', as_currency(totals[:total_net_book_value])

        r.add_section('Section2', dataset.fixed_assets) do |s|
          s.add_field(:account_label) { |account| account[:account_label] }
          s.add_field(:account_depreciable_amount) { |account| as_currency(account[:account_depreciable_amount]) }
          s.add_field(:account_depreciated_amount) { |account| as_currency(account[:account_depreciated_amount]) }
          s.add_field(:account_current_depreciation_amount) { |account| as_currency(account[:account_current_depreciation_amount]) }
          s.add_field(:account_cumulated_depreciated_amount) { |account| as_currency(account[:account_cumulated_depreciated_amount]) }
          s.add_field(:account_net_book_value) { |account| as_currency(account[:account_net_book_value]) }

          s.add_table('Table6', :assets) do |t|
            t.add_column(:label) { |asset| asset[:label] }
            t.add_column(:started_on) { |asset| asset[:started_on].strftime('%d/%m/%Y') }
            t.add_column(:duration) { |asset| asset[:duration] }
            t.add_column(:depreciable_amount) { |asset| as_currency(asset[:depreciable_amount]) }
            t.add_column(:depreciation_percentage) { |asset| asset[:depreciation_percentage] }
            t.add_column(:depreciation_method) { |asset| I18n.translate("enumerize.fixed_asset.depreciation_method.#{asset[:depreciation_method]}") }
            t.add_column(:depreciated_amount) { |asset| as_currency(asset[:depreciated_amount]) }
            t.add_column(:current_depreciation_amount) { |asset| as_currency(asset[:current_depreciation_amount]) }
            t.add_column(:cumulated_depreciated_amount) { |asset| as_currency(asset[:cumulated_depreciated_amount]) }
            t.add_column(:net_book_value) { |asset| as_currency(asset[:net_book_value]) }
          end
        end
      end
    end
  end
end
