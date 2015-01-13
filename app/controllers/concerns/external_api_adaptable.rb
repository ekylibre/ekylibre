# module ExternalApiAdaptable
# this module is intended to adapt easily Ekylibre
# to external APIs just by telling the controller
# how to translate API input/output to its Ekylibre equivalent
# this controller actions builder assumes that the controller's name
# is the API output name.

module ExternalApiAdaptable
  extend ActiveSupport::Concern

  module ClassMethods
    def manage_restfully(defaults = {})
      options = defaults.extract! :only, :except
      actions  = [:index, :show, :new, :create, :edit, :update, :destroy]
      actions &= [options[:only]].flatten   if options[:only]
      actions -= [options[:except]].flatten if options[:except]

      name = self.controller_name
      model = defaults[:model].present? ? defaults[:model].to_s.singularize.classify.constantize : name.to_s.singularize.classify.constantize rescue nil
      model = model.send defaults[:scope] if defaults[:scope].present?

      api_path = self.controller_path.split('/')[0..-2].join('/')

      output_name = name
      locals = {}
      locals[:output_name] = output_name
      locals[:partial_path] = defaults[:partial_path] || "#{output_name.pluralize}/#{output_name.singularize}"

      index = lambda do
        @records = model.all rescue []
        render template: "layouts/#{api_path}/index", locals: locals
      end

      # search_filters allow to match #show via records ids or another criteria such
      # as names or any value that might be a key
      # a search filter is a hash associating the api key to its ekylibre equivalent.
      # Example with Pasteque API : the "label" key in Pasteque is equivalent to "name"
      # in Ekylibre.
      search_filters = defaults[:search_filters] || {id: :id}

      model_fields = model.column_names -['created_at', 'updated_at', 'creator_id', 'updater_id', 'lock_version', 'left', 'right'] rescue nil

      show = lambda do
        api_key = params.slice(*search_filters.keys).keys.first
        key = search_filters[api_key.to_sym]
        @record = model.find_by(key => params[api_key]) rescue nil
        if @record.present?
          render partial: "#{api_path}/#{locals[:partial_path]}", locals:{name.singularize.to_sym => @record}
        else
          render status: :not_found, json: nil
        end
      end

      update = lambda do
        @record = model.find(params[:id])
        render :json, @record.update(permitted_params)
      end

        destroy = lambda do
          @record = model.find(params[:id])
          if @record.destroy
            render status: :ok, json: nil
          else
            render status: :method_not_allowed, json: nil
          end
        end

      method_for =
        {
          index:  index,
          show:   show,
          update: update,
          destroy: destroy
        }

      actions.each do |action|
        define_method action, method_for[action]
      end

      define_method :permitted_params do
        params.require(model.name.underscore).permit(model_fields) rescue params.permit!
      end
      define_method :model do
        model
      end
      private :permitted_params, :model
    end
  end
end
