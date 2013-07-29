# -*- coding: utf-8 -*-
class Backend::DataView::VeterinaryBookletsController < Backend::DataViewController

  def show
    campaign = Campaign.first
    respond_with_view(campaign)
  end

end
