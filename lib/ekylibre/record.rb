module Ekylibre
  module Record
    autoload :Base, 'ekylibre/record/base'
  end
end

require_relative('record/bookkeep')
require_relative('record/autosave')
require_relative('record/selects_among_all')
require_relative('record/has_shape')
require_relative('record/sums')
require_relative('record/dependents')
require_relative('record/acts/numbered')
require_relative('record/acts/reconcilable')
require_relative('record/acts/affairable')
require_relative('record/acts/protected')
