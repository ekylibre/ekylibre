module Backend
  class MeasuresController < Backend::BaseController
    def convert
      begin
        measure = Measure.new(params[:value].to_f, params[:from]).in(params[:to])
        response = { value: measure.value.to_f, unit: measure.unit }
      rescue => e
        response = { error: e }
        error = true
      end
      respond_to do |format|
        format.json { render json: response, status: error ? :unprocessable_entity : :ok }
      end
    end
  end
end
