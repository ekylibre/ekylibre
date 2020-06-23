module Ekylibre
  module Testing
    module Concerns
      module LocaleSetter
        protected def reset_locale
          ::I18n.locale = ENV.fetch('LOCALE') { ::I18n.default_locale }
        end
      end
    end
  end
end