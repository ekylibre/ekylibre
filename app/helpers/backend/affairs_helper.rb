module Backend
  module AffairsHelper
    def affair_of(deal, options = {})
      affair_deals(deal.affair, options.merge(current_deal: deal, third: deal.deal_third))
    end

    def affair_deals(affair, options = {})
      locals = {
        current_deal: options[:current_deal],
        affair: affair,
        types: (Affair.affairable_types - %w(Gap))
      }
      if options[:default]
        unless locals[:types].include? options[:default]
          raise 'Invalid default deal type: #{options[:default].inspect}. Expecting one of: ' + locals[:types].to_sentence
        end
        locals[:default_type] = options[:default]
      else
        locals[:default_type] = locals[:types].first
      end
      locals[:other_types] = locals[:types] - [locals[:default_type]]
      locals[:third_id] = options[:third] ? options[:third].id : Maybe(affair.deals.first).deal_third.or_else(nil)
      render partial: 'backend/affairs/show', object: affair, locals: locals
    end
  end
end
