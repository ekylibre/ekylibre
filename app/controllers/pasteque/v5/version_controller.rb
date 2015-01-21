class Pasteque::V5::VersionController < Pasteque::V5::BaseController
  skip_before_action :authenticate_user!

  def index
    render json: {version: "5", level: 0}
  end
end
