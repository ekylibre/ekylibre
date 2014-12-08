class Pasteque::V5::VersionsController < Pasteque::V5::BaseController
  def version
    render json: {version: "foo", level: 5}
  end
end
