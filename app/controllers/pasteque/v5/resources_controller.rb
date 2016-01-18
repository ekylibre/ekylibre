module Pasteque
  module V5
    class ResourcesController < Pasteque::V5::BaseController
      # manage_restfully only: [:show], get_filters: {label: :name}, model: :resource

      CONVERT = {
        'MobilePrinter.Header' => {
          name: 'pos.printer.ticket.header',
          nature: :string,
          default: 'Hello'
        },
        'MobilePrinter.Footer' => {
          name: 'pos.printer.ticket.footer',
          nature: :string,
          default: 'Good bye'
        }
      }.freeze

      def show
        if pref = CONVERT[params[:label]]
          unless preference = Preference.find_by(name: pref[:name])
            preference = Preference.create!(name: pref[:name], nature: pref[:nature], value: pref[:default])
          end
          render json: { status: 'ok', content: { type: 0, content: preference.value, label: params[:label], id: preference.id.to_s } }
        else
          render json: { status: 'rej', content: ['Cannot identify resource'] }
        end
      end
    end
  end
end
