# encoding: UTF-8
require 'test_helper'

class ModelsTest < Test::Unit::TestCase

  # Checks the validity of references files for models
  def test_ekylibre_models
    for k, v in Ekylibre.references
      for c, t in v
        assert(!t.blank?, "#{k}.#{c} foreign key is not determined.")
        if t.is_a? Symbol
          assert_nothing_raised do
            t.to_s.pluralize.classify.constantize
          end
        end
      end
    end
  end

end
