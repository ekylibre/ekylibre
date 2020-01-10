module RespondWithTemplate
  def respond_with (*resources, &block)
    resources << {} unless resources.last.is_a?(Hash)
    resources[-1][:with] = (params[:template].to_s =~ /^\d+$/ ? params[:template].to_i : params[:template].to_s) if params[:template]
    for param in %i[key name]
      resources[-1][param] = params[param] if params[param]
    end

    super(*resources, &block)
  end
end
