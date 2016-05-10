require 'test_helper'

module Nomen
  class NomenclatureSetTest < ActiveSupport::TestCase
    setup do
      I18n.locale = ENV['LOCALE']
    end

    test 'set manipulation' do
      set = Nomen::NomenclatureSet.new
      set.add_nomenclature(:vehicles)
      set.add_property(:vehicles, :height, :decimal)
      set.add_item(:vehicles, :truck,  height: 3)
      set.add_property(:vehicles, :length, :decimal)
      set.add_item(:vehicles, :car, height: 1.5, length: 4)
      set.add_item(:vehicles, :race_car, parent: :car)
      set.add_item(:vehicles, :dragster, parent: :race_car)
      set.add_item(:vehicles, :race_vehicle)
      set.change_item(:vehicles, :race_car, parent: :race_vehicle)
      set.add_item(:vehicles, :radioactive_dragster, parent: :dragster)
      set.change_item(:vehicles, :race_car, parent: nil)
      set.add_nomenclature(:trailers)

      assert !set.nomenclature(:behicles)
      assert !set.nomenclature('behicles')
      assert set.nomenclature(:vehicles)
      assert set.nomenclature('vehicles')
      assert set.item(:vehicles, :truck)
      assert set.item(:vehicles, :dragster)
      assert set.item(:vehicles, :dragster).parent, 'Dragster should have parent'
      assert set.item(:vehicles, :dragster).parent == :race_car
      assert set.item(:vehicles, :dragster) < :race_car, ':dragster should be inferior to :race_vehicle'
      assert set.item(:vehicles,  :race_vehicle) == :race_vehicle
      assert set.item('vehicles', :race_vehicle) == :race_vehicle
      assert set.item(:vehicles,  'race_vehicle') == :race_vehicle
      assert set.item('vehicles', 'race_vehicle') == :race_vehicle
    end
  end
end
