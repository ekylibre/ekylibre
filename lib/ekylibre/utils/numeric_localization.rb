# frozen_string_literal: true

module Ekylibre
  module Utils
    module NumericLocalization
      refine ::Numeric do
        def round_l(precision: 2, **i18n_options)
          ::I18n.localize(round(precision), precision: precision, **i18n_options)
        end

        def round_l_auto(precision_min: 2, precision_max: 4, **i18n_options)
          precision = [precision_min, [precision_max, self.to_f.to_s.split('.').last.size].min].max

          round_l(precision: precision, **i18n_options)
        end
      end
    end
  end
end
