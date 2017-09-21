module Backend
  module AffairsHelper
    def affair_of(deal, options = {})
      affair_deals(deal.affair, options.merge(current_deal: deal, third: deal.deal_third))
    end

    def affair_deals(affair, options = {})
      return nil unless affair
      types = if affair.is_a?(SaleAffair)
                %w[Sale IncomingPayment]
              elsif affair.is_a?(PurchaseAffair)
                %w[PurchaseInvoice PurchasePayment]
              elsif affair.is_a?(PayslipAffair)
                %w[Payslip PayslipPayment]
              else
                (Affair.affairable_types - %w[Gap PurchaseGap SaleGap])
              end
      current_deal = options[:current_deal]
      if current_deal && (current_deal.class.name + 'Affair' == affair.class.name)
        types.reverse!
      end
      locals = {
        current_deal: current_deal,
        affair: affair,
        types: types
      }
      if options[:default]
        unless locals[:types].include? options[:default]
          locals[:types] << options[:default]
          # raise 'Invalid default deal type: ' + options[:default].inspect + '. Expecting one of: ' + locals[:types].to_sentence
        end
        locals[:default_type] = options[:default]
      else
        locals[:default_type] = locals[:types].first
      end
      locals[:other_types] = locals[:types] - [locals[:default_type]]
      locals[:third_id] = options[:third] ? options[:third].id : Maybe(affair.deals.first).deal_third.or_else(nil)
      locals[:new_record_options] = options[:url_options] || {}
      render partial: 'backend/affairs/show', object: affair, locals: locals
    end
  end
end
