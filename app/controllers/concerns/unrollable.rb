# Concern that allows a support for the JS searchable selectors.
module Unrollable
  extend ActiveSupport::Concern

  # Create unroll action for all scopes in the model corresponding to the controller including the default scope
  module ClassMethods
    def unroll(*args)
      options = Unrollable::Extracting.options_from(args, defaults: true)

      default_scope = options[:scope]

      columns = Unrollable::ColumnList.new(args, controller_name.classify.constantize)

      filters = columns.to_filters
      fill_in = Unrollable::Extracting.fill_in_from(options, filters)
      searchable_filters = Unrollable::Filter.searchables_in(filters, controller_path)
      order = options[:order] || filters.map(&:search)

      define_method :unroll do
        model_name = controller_name.classify
        model      = model_name.constantize
        scopes = Unrollable::Extracting.scopes_from(params)
        excluded_records = params[:exclude]
        search_term = params[:q].to_s.strip
        keys = search_term.mb_chars.downcase.normalize.split(/[\s\\,]+/)

        items = Unrollable::ItemRelation.new(model.send(default_scope))

        kept = items.keeping(params[:id])

        begin
          filtered_items = items.filter_through(model, columns, order, scopes, excluded_records)
        rescue InvalidScopeException => e
          logger.error e.message
          head :bad_request
          return false
        end
        kept ||= filtered_items.keeping(params[:id]) unless Unrollable::Toolbelt.true?(params[:keep])

        items = kept || filtered_items.ordered_matches(keys, searchable_filters, search_term.mb_chars.downcase.normalize)

        respond_to do |format|
          data_only_view = proc { items.map { |item| { label: UnrollHelper.label_item(item, filters, controller_path), id: item.id } } }
          format.html { render partial: 'unrolled', locals: { max: options[:max], items: items, fill_in: fill_in, keys: keys, filters: filters, render_partial: options[:partial], search: search_term.capitalize, model_name: model_name, visible_items_count: options[:visible_items_count] }, layout: false }
          format.json { render json: data_only_view.call }
          format.xml  { render xml:  data_only_view.call }
        end
      end
    end
  end
end
