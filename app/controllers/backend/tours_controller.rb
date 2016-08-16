module Backend
  class ToursController < Backend::BaseController
    def finish
      tour = params[:id].to_s.strip
      if tour.blank?
        head :not_found
      else
        p = current_user.preference("interface.tours.#{tour}.finished", false, :boolean)
        p.set!(true)
        head :ok
      end
    end
  end
end
