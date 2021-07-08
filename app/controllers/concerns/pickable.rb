module Pickable
  extend ActiveSupport::Concern

  module ClassMethods
    def importable_from_lexicon(lexicon_table, model_name: nil, primary_key: :id, filters: {})
      record_name = controller_name.singularize
      model = model_name || controller_name.classify.constantize
      lexicon_model = lexicon_table.to_s.classify.constantize

      define_method :pick do
        instance_variable_set "@#{record_name}", model.new
        @lexicon_table = lexicon_table
        @primary_key = primary_key
        imported_references = model.pluck(:reference_name).uniq.compact
        @imported_ids = lexicon_model.including_references(imported_references).pluck(primary_key)
        @scopes = filters
        @key = record_name
      end

      define_method :incorporate do
        reference_name = lexicon_model.find_by(primary_key => params[:reference_id]).reference_name
        instance_variable_set "@#{record_name}", model.send('import_from_lexicon', reference_name, true)

        if params[:redirect_show_path].present?
          show_url = params[:redirect_show_path] + '/' + instance_variable_get("@#{record_name}").id.to_s
        end

        if params[:redirect_show_path].present? && params[:redirect_edit_path].present?
          edit_url = params[:redirect_edit_path] + '/' + instance_variable_get("@#{record_name}").id.to_s + '/edit?' + { redirect: show_url }.to_query
        end

        notify_success :record_has_been_imported
        redirect_to edit_url || show_url || :back
      rescue => e
        notify_error :an_error_was_raised_during_import
        redirect_to params[:redirect_show_path] || :back
      end
    end

    def importable_from_nomenclature(nomenclature_table, model_name: nil, filters: {})
      record_name = controller_name.singularize
      model = model_name || controller_name.classify.constantize
      nomenclature_model = "Onoma::#{nomenclature_table.to_s.classify}".constantize

      define_method :pick do
        instance_variable_set "@#{record_name}", model.new
        imported_references = model.pluck(:reference_name).uniq.compact
        items = nomenclature_model.without(imported_references)
        items = nomenclature_model.where(filters, items) if filters.any?
        @available_items = items.selection
        @key = record_name
      end

      define_method :incorporate do
        instance_variable_set "@#{record_name}", model.send('import_from_nomenclature', params[record_name][:reference_name], true)

        if params[:redirect_show_path].present?
          show_url = params[:redirect_show_path] + '/' + instance_variable_get("@#{record_name}").id.to_s
        end

        if params[:redirect_show_path].present? && params[:redirect_edit_path].present?
          edit_url = params[:redirect_edit_path] + '/' + instance_variable_get("@#{record_name}").id.to_s + '/edit?' + { redirect: show_url }.to_query
        end

        notify_success :record_has_been_imported
        redirect_to edit_url || show_url || :back
      rescue => e
        notify_error :an_error_was_raised_during_import
        redirect_to params[:redirect_show_path] || :back
      end
    end
  end
end
