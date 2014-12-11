class Pasteque::V5::VersionsController < Pasteque::V5::BaseController
  def version
    render json: {version: "5", level: 0}
  end
end
