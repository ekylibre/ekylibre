require 'test_helper'

module Backend
  class PhytosanitaryRegistersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    # These tests render the full backend layout which depends on the webpacker
    # `packs-test` manifest. The manifest is empty by default in this dev image —
    # see /app/public/packs-test/manifest.json. Run `bin/webpack` once (or
    # `RAILS_ENV=test bundle exec rake webpacker:compile`) before running these
    # in CI/local. Skipping by default so the controller logic suite stays green.
    test 'index renders successfully' do
      skip 'requires compiled webpacker packs-test manifest'
      get :index
      assert_response :success
    end

    test 'preview renders with valid campaign' do
      skip 'requires compiled webpacker packs-test manifest'
      get :preview, params: { campaign_id: campaigns(:campaigns_001).id }
      assert_response :success
      assert_kind_of Phytosanitary::Register::Payload, assigns(:payload)
      assert_kind_of Phytosanitary::Register::IntegrityValidator::Result, assigns(:validation)
    end

    test 'preview renders even with no campaign' do
      skip 'requires compiled webpacker packs-test manifest'
      get :preview
      assert_response :success
    end

    test 'create with unsupported format redirects with error' do
      post :create, params: { campaign_id: campaigns(:campaigns_001).id, export_format: 'pdf' }
      assert_redirected_to action: :index
    end

    test 'create with xml format archives a Document and redirects to it' do
      assert_difference -> { Document.where(nature: 'phytosanitary_register').count }, 1 do
        post :create, params: { campaign_id: campaigns(:campaigns_001).id, export_format: 'xml', force: 'true' }
      end
      assert_response :redirect
      document = Document.where(nature: 'phytosanitary_register').order(:created_at).last
      assert document.name.end_with?('.xml')
    end

    test 'create with json format archives a Document' do
      assert_difference -> { Document.where(nature: 'phytosanitary_register').count }, 1 do
        post :create, params: { campaign_id: campaigns(:campaigns_001).id, export_format: 'json', force: 'true' }
      end
      document = Document.where(nature: 'phytosanitary_register').order(:created_at).last
      assert document.name.end_with?('.json')
    end

    test 'create with csv format archives a Document' do
      assert_difference -> { Document.where(nature: 'phytosanitary_register').count }, 1 do
        post :create, params: { campaign_id: campaigns(:campaigns_001).id, export_format: 'csv', force: 'true' }
      end
      document = Document.where(nature: 'phytosanitary_register').order(:created_at).last
      assert document.name.end_with?('.csv')
    end

    test 'create without force on incomplete payload redirects to preview' do
      campaign = campaigns(:campaigns_001)
      stub_validator = ::Phytosanitary::Register::IntegrityValidator::Result.new(
        errors_by_entry: { [1, 2, 3] => [:product_name] }
      )
      ::Phytosanitary::Register::IntegrityValidator.stub :call, stub_validator do
        post :create, params: { campaign_id: campaign.id, export_format: 'xml' }
      end
      assert_response :redirect
    end
  end
end
