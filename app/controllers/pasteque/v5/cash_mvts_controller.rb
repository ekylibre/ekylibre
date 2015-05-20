class Pasteque::V5::CashMvtsController < Pasteque::V5::BaseController
 def move
    render json: {status: :rej, content: ["Not supported"]}
  end
end
