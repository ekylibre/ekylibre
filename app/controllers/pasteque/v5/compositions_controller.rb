class Pasteque::V5::CompositionsController < Pasteque::V5::BaseController
  def index
    render json: { status: 'ok', content: [] }
  end
end
