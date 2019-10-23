class RegisteredHydroItem < ActiveRecord::Base
  include Lexiconable

  scope :in_bounding_box, lambda { |bounding_box|
    where(<<-SQL)
      registered_hydro_items.shape && ST_MakeEnvelope(#{bounding_box.join(', ')})
      OR registered_hydro_items.lines && ST_MakeEnvelope(#{bounding_box.join(', ')})
      OR registered_hydro_items.point && ST_MakeEnvelope(#{bounding_box.join(', ')})
    SQL
  }

end