require 'test_helper'

class ShapeCorrectorTest < Ekylibre::Testing::ApplicationTestCase
  setup do
    @corrector = ShapeCorrector.build

    @shape = Charta.new_geometry(<<~EWKT)
      SRID=4326;MultiPolygon (((4.908266058720982 46.91016375994975, 4.908266060002689 46.91016375902789, 4.90865146378712 46.91013522972928, 4.908857900381218 46.91012736923464, 4.908855557441711 46.9101271141826, 4.908828735351563 46.9101271141826, 4.908834099769592 46.91017475492051, 4.908867665754878 46.91012750102963, 4.908899977650015 46.91024305558259, 4.909021604251901 46.91053652156399, 4.909181736780146 46.91093084006668, 4.90863561630249 46.91103228096193, 4.908447861671448 46.91059985501492, 4.908266040459607 46.91016376385473, 4.908266056189317 46.91016376269356, 4.908266058720982 46.91016375994975)))
    EWKT
  end

  test "can fix shape" do
    corrected = @corrector.try_fix(@shape)

    assert corrected.is_some?
  end

  test "returns None if the change is not within the threshold" do
    stub_many @corrector, area_ratio: Some(12) do
      assert @corrector.try_fix(@shape).is_none?
    end

    stub_many @corrector, area_ratio: None() do
      assert @corrector.try_fix(@shape).is_none?
    end
  end

  test "returns None if postgis fix fails" do
    stub_many @corrector, try_postgis_fix: None() do
      assert @corrector.try_fix(@shape).is_none?
    end
  end

  test "area_ratio returns None if the original area is 0" do
    assert @corrector.send(:area_ratio, {area: 0}.to_struct, {area: 42}.to_struct).is_none?
  end
end