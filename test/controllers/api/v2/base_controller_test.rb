require 'test_helper'
module Api
  module V2
    class BaseControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      test 'set_local before filter' do
        User.find_by(email: 'admin@ekylibre.org').update(language: nil)
        Preference.set!(:language, nil)

        @controller.send(:set_locale)
        assert_equal I18n.default_locale, I18n.locale

        language = :eng
        Preference.set!(:language, language)
        @controller.send(:set_locale)
        assert_equal language, I18n.locale

        language = :fra
        User.find_by(email: 'admin@ekylibre.org').update(language: language)
        @controller.send(:authenticate_api_user!)
        @controller.send(:set_locale)
        assert_equal language, I18n.locale

        language = :eng
        @controller.params[:locale] = language
        @controller.send(:set_locale)
        assert_equal language, I18n.locale
      end

      test 'set_local before filter with header' do
        User.find_by(email: 'admin@ekylibre.org').update(language: nil)
        Preference.set!(:language, nil)
        session = { session: nil }

        accept_language = 'fr'
        request.headers['Accept-Language'] = accept_language
        @controller.send(:set_locale)
        assert_equal :fra, I18n.locale
        request.headers['Accept-Language'] = nil
      end

    end
  end
end
