require 'test_helper'
module Api
  module V2
    class CultivableZonesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      test '#index return all cultivable zones' do
        get :index, params: {}
        cultivable_zones = JSON.parse(response.body)
        assert_equal 39, cultivable_zones.count
      end

      test '#create a cultivable zone' do
        name = 'name'
        shape = "SRID=4326;MultiPolygon (((-0.792163257283729 45.8212392141659, -0.791904819365336 45.8212103045779, -0.791480654542158 45.8212221132556, -0.791101405009501 45.8211429977115, -0.79069849642266 45.821064450282, -0.791605612418384 45.8202552159891, -0.792163257283729 45.8212392141659)))"
        post :create, params: { name: name, shape: shape }
        assert_response :created
        uuid = JSON.parse(response.body)['uuid']
        created_cultivable_zone = CultivableZone.find_by(uuid: uuid)
        assert_equal(name, created_cultivable_zone.name)
        assert_equal(shape, created_cultivable_zone.shape.to_s)
      end

      test '#update a cultivable zone' do
        cultivable_zone = CultivableZone.first
        new_name = 'new name'
        new_shape = "SRID=4326;MultiPolygon (((-0.792163257283729 45.8212392141659, -0.791904819365336 45.8212103045779, -0.791480654542158 45.8212221132556, -0.791101405009501 45.8211429977115, -0.79069849642266 45.821064450282, -0.791605612418384 45.8202552159891, -0.792163257283729 45.8212392141659)))"
        put :update, params: { uuid: cultivable_zone.uuid, name: new_name, shape: new_shape }
        assert_response :ok
        uuid = JSON.parse(response.body)['uuid']
        updated_cultivable_zone = CultivableZone.find_by(uuid: uuid)
        assert_equal(new_name, updated_cultivable_zone.name)
        assert_equal(new_shape, updated_cultivable_zone.shape.to_s)
      end
    end
  end
end
