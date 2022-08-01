require 'test_helper'
module Backend
  class AttachmentsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[destroy create]

    test 'Create action without attachments params' do
      post :create, params: default_params, format: :json
      assert_response 422
    end

    test 'Create action with attachments params' do
      attachment = attachments(:attachments_001)
      document = attachment.document
      params = default_params.merge(
        {
          attachments: {
            resource_type: attachment.resource_type,
            nature: attachment.nature,
            document_attributes: {
              name: document.name,
              key: document.key
            },
          }
        }
      )
      post :create, params: params, format: :json
      assert_response :created
    end

    test 'Create action with wrong attachments params' do
      attachment = attachments(:attachments_001)
      document = attachment.document
      params = default_params.merge(
        {
          attachments: {
            resource_type: attachment.resource_type,
            nature: attachment.nature,
            document_attributes: {},
          }
        }
      )

      post :create, params: params, format: :json
      assert_response 422
      assert JSON.parse(response.body).any?
    end

    test 'destroy action' do
      attachment = attachments(:attachments_002)
      delete :destroy, params: { id: attachment.id }
      assert_response :ok
      assert_equal 'deleted', JSON.parse(response.body)['attachment']
    end

    private

      def default_params
        {
          subject_type: 'Entity',
          subject_id: 2
        }
      end
  end
end
