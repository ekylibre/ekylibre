class Pasteque::V5::VersionController < Pasteque::V5::BaseController
  def index
    render json: {version: "5", level: 0}
  end
end
