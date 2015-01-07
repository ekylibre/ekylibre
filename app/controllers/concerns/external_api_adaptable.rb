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
      model = defaults[:model].present? ? defaults[:model].to_s.singularize.classify.constantize : name.to_s.singularize.classify.constantize
      model = model.send defaults[:scope] if defaults[:scope].present?

      api_path = self.controller_path.split('/')[0..-2].join('/')

      output_name = name
      locals = {}
      locals[:output_name] = output_name
      locals[:partial_path] = defaults[:partial_path] if defaults[:partial_path]
      locals[:record] = defaults[:record] if defaults[:record]

      methods =
        {
          index:  lambda{@records = model.all; render template: "layouts/#{api_path}/index", locals: locals},
          show:   lambda{@record = model.find(permitted_params[:id]) rescue nil; render template: "layouts/#{api_path}/show", locals:{output_name: output_name.to_s.singularize}.merge(locals)}
        }

      actions.each do |action|
        define_method action, methods[action]
      end

      define_method :permitted_params do
        params.permit!
      end
      private :permitted_params
    end
  end
end
