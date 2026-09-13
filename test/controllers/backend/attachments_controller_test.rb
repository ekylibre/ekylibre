require 'test_helper'
module Backend
  class AttachmentsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # `show` est exclu du parcours générique : il ne rend 200 que si le document
    # porte un fichier, et les fixtures n'en attachent aucun — le 404 obtenu
    # était le comportement voulu du contrôleur, pas un défaut. Les deux cas
    # sont couverts explicitement ci-dessous.
    test_restfully_all_actions except: %i[destroy create show]

    test 'show returns 404 when the document carries no file' do
      attachment = attachments(:attachments_001)
      get :show, params: { id: attachment.id }, format: :json
      assert_response :not_found
    end

    test 'show returns the document path when a file is attached' do
      attachment = attachments(:attachments_001)
      attachment.document.file.attach(
        io: File.open(Rails.root.join('test', 'fixture-files', 'outgoing_deliveries.pdf')),
        filename: 'outgoing_deliveries.pdf',
        content_type: 'application/pdf'
      )

      get :show, params: { id: attachment.id }, format: :json
      assert_response :success
      assert_equal attachment.name, JSON.parse(response.body)['name']
    end

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
