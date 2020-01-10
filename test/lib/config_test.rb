require 'test_helper'

class ConfigTest < ActiveSupport::TestCase
  test 'paperclip interpolations' do
    tenant = Ekylibre::Tenant.current
    assert_equal 'test', tenant
    assert_equal Ekylibre::Tenant.private_directory.to_s,
                 Paperclip::Interpolations.interpolate(':private', nil, nil)
    assert_equal Ekylibre::Tenant.private_directory.join('attachments').to_s,
                 Paperclip::Interpolations.interpolate(':tenant', nil, nil)
  end

end
