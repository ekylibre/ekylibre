# encoding: UTF-8
require 'test_helper'

class Ekylibre::FirstRunTest < ActiveSupport::TestCase
  teardown do
    Ekylibre::Tenant.switch!('test')
  end

  test 'launch of default first run' do
    tenant = 'test_default'
    Ekylibre::Tenant.drop(tenant) if Ekylibre::Tenant.exist?(tenant)
    Ekylibre::FirstRun.launch(name: tenant, path: Rails.root.join('db', 'first_runs', 'default'), verbose: false)
  end

  # test "launch of test first run" do
  #   Ekylibre::FirstRun.launch(path: Rails.root.join("test", "fixtures", "files", "first_run"), name: :sekindov)
  # end
end
