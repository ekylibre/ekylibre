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
      options = defaults.extract! :except, :model, :only, :output_name, :partial_path, :resource_name, :scope
      actions  = [:index, :show, :new, :create, :edit, :destroy, :search]
      actions &= [options[:only]].flatten   if options[:only]
      actions -= [options[:except]].flatten if options[:except]

      name = controller_name
      resource_name = options[:resource_name] || name.to_s.singularize.to_sym
      model = begin
                options[:model].present? ? options[:model].to_s.singularize.classify.constantize : name.to_s.singularize.classify.constantize
              rescue
                nil
              end
      model = model.send options[:scope] if options[:scope].present?

      api_path = controller_path.split('/')[0..-2].join('/')

      output_name = options[:output_name] || name
      locals = {}
      locals[:output_name] = output_name
      locals[:partial_path] = options[:partial_path] || "#{output_name.pluralize}/#{output_name.singularize}"

      index = lambda do
        @records = begin
                     model.all
                   rescue
                     []
                   end
        render locals: locals
      end

      # get_filters allow to match #show via records ids or another criteria such
      # as names or any value that might be a key
      # a search filter is a hash associating the api key to its ekylibre equivalent.
      # Example with Pasteque API : the "label" key in Pasteque is equivalent to "name"
      # in Ekylibre.
      get_filters = defaults[:get_filters] || { id: :id }

      model_fields = begin
                       model.column_names - %w(created_at updated_at creator_id updater_id lock_version left right)
                     rescue
                       nil
                     end

      show = lambda do
        api_key = params.slice(*get_filters.keys).keys.first
        key = get_filters[api_key.to_sym]
        @record = model.find_by(key => params[api_key]) # rescue nil
        # puts [key, api_key, params[api_key], @record, model].inspect.red
        if @record.present?
          render locals: locals
        else
          render json: { status: :rej, content: 'Cannot find record' }
        end
      end

      create = lambda do
        matching = defaults[:update_filters].with_indifferent_access
        create_params = permitted_params.slice(*matching.keys).inject({}) do |h, p|
          h[matching[p.first]] = p.second
          h
        end
        record = model.new(create_params)
        if record.save
          render locals: { output_name.singularize.to_sym => record }
        else
          render json: { status: :rej, content: 'Cannot create record' }
        end
      end

      destroy = lambda do
        @record = model.find(params[:id])
        if @record.destroy
          render json: { status: :ok }
        else
          render json: { status: :rej, content: 'Cannot destroy record' }
        end
      end

      search = lambda do
        matching = defaults[:search_filters].with_indifferent_access
        criterias = params.slice(*matching.keys).inject({}) do |h, p|
          h[matching[p.first]] = p.second
          h
        end
        @records = model.where(criterias)
        render locals: locals
      end

      method_for = {
        index:  index,
        show:   show,
        search: search,
        create: create,
        # update: update,
        destroy: destroy
      }

      actions.each do |action|
        define_method action, method_for[action]
      end

      define_method :permitted_params do
        params.require(resource_name).permit(*model_fields) # rescue params.permit!
      end

      define_method :model do
        model
      end

      private :permitted_params, :model
    end
  end
end
