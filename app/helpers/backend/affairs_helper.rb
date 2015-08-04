module Backend::AffairsHelper
  def affair_of(deal)
    render partial: 'backend/affairs/show', object: deal.affair, locals: { affair: deal.affair, current_deal: deal }
  end

  def affair_deals(affair)
    render partial: 'backend/affairs/show', object: affair, locals: { affair: affair, current_deal: nil }
  end
end
