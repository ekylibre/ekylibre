require 'test_helper'
require 'ekylibre/tenancy'
require 'ekylibre/tenancy/job_propagation'

# Le contexte de ferme, éprouvé sur la base de test — pas sur le mono-schéma :
# ce qui se mesure ici, c'est la mécanique du contexte (pose, restitution,
# imbrication, cache, propagation aux jobs). Que la base ne rende rien sans
# contexte est mesuré à part, par le prototype, qui a la RLS.
class TenancyTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  ALPHA = '11111111-1111-7111-8111-111111111111'.freeze
  BETA = '22222222-2222-7222-8222-222222222222'.freeze

  teardown do
    Ekylibre::Tenancy::Current.reset
  end

  test 'le contexte est posé dans la session et dans la base' do
    Ekylibre::Tenancy.with(ALPHA) do
      assert_equal ALPHA, Ekylibre::Tenancy.current
      assert_equal ALPHA, setting
    end
  end

  test 'il est rendu à sa valeur précédente en sortant' do
    Ekylibre::Tenancy.with(ALPHA) do
      Ekylibre::Tenancy.with(BETA) { assert_equal BETA, setting }
      assert_equal ALPHA, setting, 'le contexte imbriqué ne doit pas survivre à son bloc'
      assert_equal ALPHA, Ekylibre::Tenancy.current
    end
    assert_equal '', setting
  end

  test 'une exception ne laisse pas le contexte derrière elle' do
    assert_raises(RuntimeError) do
      Ekylibre::Tenancy.with(ALPHA) { raise 'échec au milieu du bloc' }
    end

    assert_nil Ekylibre::Tenancy.current
    assert_equal '', setting
  end

  test 'sortir de toute ferme est explicite, et réversible' do
    Ekylibre::Tenancy.with(ALPHA) do
      Ekylibre::Tenancy.without_tenant do
        assert_nil Ekylibre::Tenancy.current
        assert_equal '', setting
      end
      assert_equal ALPHA, setting
    end
  end

  test 'le cache de requêtes ne resservit pas la lecture du voisin' do
    # Sans vidage, la seconde lecture — même texte SQL — rendrait la valeur
    # lue sous la première ferme. C'est le piège mesuré sur le prototype.
    ApplicationRecord.connection.cache do
      first = Ekylibre::Tenancy.with(ALPHA) { setting }
      second = Ekylibre::Tenancy.with(BETA) { setting }

      assert_equal ALPHA, first
      assert_equal BETA, second
    end
  end

  test 'current! réclame un contexte plutôt que de rendre nil' do
    assert_raises(Ekylibre::Tenancy::MissingTenant) { Ekylibre::Tenancy.current! }
    Ekylibre::Tenancy.with(ALPHA) { assert_equal ALPHA, Ekylibre::Tenancy.current! }
  end

  test 'un job emporte la ferme de la requête qui l’a enfilé' do
    job = TenantAwareJob.new
    serialized = Ekylibre::Tenancy.with(ALPHA) { job.serialize }

    assert_equal ALPHA, serialized['tenant_id']

    # Exécuté plus tard, hors de tout contexte : il le rétablit lui-même.
    TenantAwareJob.seen = nil
    ActiveJob::Base.execute(serialized)

    assert_equal ALPHA, TenantAwareJob.seen
    assert_nil Ekylibre::Tenancy.current, 'le job ne doit pas laisser son contexte au processus'
  end

  class TenantAwareJob < ActiveJob::Base
    include Ekylibre::Tenancy::JobPropagation

    class << self
      attr_accessor :seen
    end

    def perform
      self.class.seen = Ekylibre::Tenancy.current
    end
  end

  private

    def setting
      ApplicationRecord.connection.select_value("SELECT current_setting('app.tenant_id', true)")
    end
end
