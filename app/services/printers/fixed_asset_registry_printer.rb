module Printers
  class FixedAssetRegistryPrinter < PrinterBase

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(stopped_on:)
        stopped_on
      end
    end

    def initialize(*_args, stopped_on:, template:, **_options)
      super(template: template)
      @stopped_on = Date.parse stopped_on
    end

    def key
      self.class.build_key(stopped_on: @stopped_on.to_s)
    end

    def document_name
      "#{@template.nature.human_name} (#{:at.tl} #{@stopped_on.l})"
    end

    def compute_dataset
      fixed_assets_by_account = FixedAsset.used.start_before(@stopped_on).group_by(&:asset_account_id)

      fixed_asset_dataset = fixed_assets_by_account.map do |asset_account_id, fixed_assets|
        account = Account.find(asset_account_id)
        account_label = "(#{account.number}) #{account.name}"

        assets = fixed_assets.map do |fixed_asset|
          amount = fixed_asset.purchase_items.any? ? fixed_asset.purchase_items.pluck(:amount).sum : fixed_asset.depreciable_amount
          # Depreciated value at the end of the period that containe @stopped_on
          cumulated_depreciated_amount = fixed_asset.already_depreciated_value(@stopped_on) || 0.0
          # Amount depreciated during this period
          current_depreciation_amount = fixed_asset.current_depreciation(@stopped_on)&.amount || 0.0
          # Total depreciated - depreciated this period = value at the start of the period
          depreciated_amount = cumulated_depreciated_amount - current_depreciation_amount

          duration = if fixed_asset.depreciation_method_none? # Stopped_on can be nil if depreciation_method is 'none'
                       ''
                     else
                       fixed_asset.stopped_on.year - fixed_asset.started_on.year
                     end

          {
            label: fixed_asset.name,
            started_on: fixed_asset.started_on,
            duration: duration,
            amount: amount,
            tax_amount: amount - fixed_asset.depreciable_amount,
            depreciable_amount: fixed_asset.depreciable_amount,
            depreciation_percentage: fixed_asset.depreciation_percentage,
            depreciation_method: fixed_asset.depreciation_method,
            depreciated_amount: depreciated_amount,
            current_depreciation_amount: current_depreciation_amount,
            cumulated_depreciated_amount: cumulated_depreciated_amount,
            net_book_value: fixed_asset.depreciable_amount - cumulated_depreciated_amount
          }
        end

        {
          account_label: account_label,
          account_amount: assets.map { |asset| asset[:amount] }.sum,
          account_depreciable_amount: assets.map { |asset| asset[:depreciable_amount] }.sum,
          account_depreciated_amount: assets.map { |asset| asset[:depreciated_amount] }.sum,
          account_current_depreciation_amount: assets.map { |asset| asset[:current_depreciation_amount] }.sum,
          account_cumulated_depreciated_amount: assets.map { |asset| asset[:cumulated_depreciated_amount] }.sum,
          account_net_book_value: assets.map { |asset| asset[:net_book_value] }.sum,
          assets: assets.sort { |a, b| a[:started_on] <=> b[:started_on] }
        }
      end

      totals = {
        total_amount: fixed_asset_dataset.map { |account_details| account_details[:account_amount] }.sum,
        total_depreciable_amount: fixed_asset_dataset.map { |account_details| account_details[:account_depreciable_amount] }.sum,
        total_depreciated_amount: fixed_asset_dataset.map { |account_details| account_details[:account_depreciated_amount] }.sum,
        total_current_depreciation_amount: fixed_asset_dataset.map { |account_details| account_details[:account_current_depreciation_amount] }.sum,
        total_cumulated_depreciated_amount: fixed_asset_dataset.map { |account_details| account_details[:account_cumulated_depreciated_amount] }.sum,
        total_net_book_value: fixed_asset_dataset.map { |account_details| account_details[:account_net_book_value] }.sum
      }

      {
        fixed_assets: fixed_asset_dataset,
        totals: totals,
        company_address: Entity.of_company.default_mail_address&.coordinate
      }.to_struct
    end

    def currency
      @currency ||= Nomen::Currency.find(Preference[:currency])
    end

    def as_currency(value)
      value.l(currency: currency.name, precision: 2)
    end

    def run_pdf
      grouped_dataset = compute_dataset
      fixed_assets = [{ # Hack to still be compatible with the way the document is structured
                        assets: grouped_dataset.fixed_assets.flat_map { |g| g[:assets] }.sort { |a, b| a[:started_on] <=> b[:started_on] }
                      }]


      totals = grouped_dataset.totals

      generate_report(@template_path) do |r|
        r.add_field 'COMPANY_ADDRESS', grouped_dataset.company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILE_NAME', key
        r.add_field 'STOPPED_ON', @stopped_on.to_date.l
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'TOTAL_AMOUNT', as_currency(totals[:total_amount])
        r.add_field 'TOTAL_DEPRECIABLE_AMOUNT', as_currency(totals[:total_depreciable_amount])
        r.add_field 'TOTAL_DEPRECIATED_AMOUNT', as_currency(totals[:total_depreciated_amount])
        r.add_field 'TOTAL_CURRENT_DEPRECIATION_AMOUNT', as_currency(totals[:total_current_depreciation_amount])
        r.add_field 'TOTAL_CUMULATED_DEPRECIATION_AMOUNT', as_currency(totals[:total_cumulated_depreciated_amount])
        r.add_field 'TOTAL_NET_BOOK_VALUE', as_currency(totals[:total_net_book_value])

        r.add_section('Section1', fixed_assets) do |s|
          s.add_table('Table2', :assets) do |t|
            t.add_column(:label) { |asset| asset[:label] }
            t.add_column(:started_on) { |asset| asset[:started_on].strftime('%d/%m/%Y') }
            t.add_column(:amount) { |asset| as_currency(asset[:amount]) }
            t.add_column(:tax_amount) { |asset| asset[:tax_amount] }
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
