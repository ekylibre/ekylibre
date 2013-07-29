# -*- coding: utf-8 -*-
class Backend::DataView::VeterinaryBookletsController < Backend::DataViewController

  def show
    campaign = Campaign.first
    respond_with_view(campaign)

    # @aggregator = Aggeratio::VeterinaryBooklet.new(campaign)
    # respond_with @aggregator
  end

end
