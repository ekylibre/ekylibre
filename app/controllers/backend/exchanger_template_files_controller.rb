module Backend
  class ExchangerTemplateFilesController < Backend::BaseController
    def show
      raise ActionController::RoutingError, 'Not Found' if file_path.is_none?

      send_file file_path.get, file_name: file_name
    end

    private

    def exchanger_name
      params[:id].gsub(/[^a-z0-9_]/i, '')
    end

    def file_path
      ActiveExchanger::Base.template_file_for(exchanger_name, locale)
    end

    def file_name
      "exchangers.#{exchanger_name}".t.parameterize + File.extname(file_path.get)
    end
  end
end
