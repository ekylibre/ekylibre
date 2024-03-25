module Clients
  module Mistral
    class Ner
      API_KEY = ENV['MISTRAL_API_KEY']
      BASE_URL = 'https://api.mistral.ai/v1/chat/completions'.freeze
      DEFAULT_BS_INSTRUCTION = <<~TEXT.freeze
        From the user prompt coming from bank statement below, extract Organizations strictly as instructed below for each item.
        Most of the time, the pattern of an item is composed of [payment_mode, Organization, transaction_number]
        1. First, look for the Organization Entity type in the text and extract the needed information defined below:
        `id` property of each item must be alphanumeric and must be unique among the items.
        `id` property of each item is present at the beginning of each item and is an integer.
        You will be referring this property to define the relationship between entities. NEVER create new entity types that aren't mentioned below.
        name of the entity must be store under 'name' property.
        Try to detect if the entity nature is a physical person or an organisation under `nature` property
        Try to detect the transaction_number under `transaction_number` property
        Document must be summarized and stored inside Organization entity under `description` property
          Entity Types:
          label:'Organization',id:integer,name:string,nature:string,payment_mode:string,transaction_number:string,role:string,description:string //Organization Node
        2. Description property should be a crisp text summary and MUST NOT be more than 100 characters
        3. If you cannot find any information on the entities & relationships above, it is okay to return empty value. DO NOT create fictious data
        4. Extract the payment mode in under 'payment_mode' property and try to match with this list : [ card, direct_debit, transfer, paid_check ]
        the rules for extracting payment_mode to match with the list is :
         PRELEVEMENT match with direct_debit
         VIREMENT match with transfer
         VIREMENT EMIS WEB match with transfer
         CHEQUE EMIS match with paid_check
         REMBOURSEMENT DE PRET match with direct_debit.#{' '}
        5. If you cannot find any information about payment mode above, it is okay to return empty value.
        6. Restrict yourself to extract only Organization information, payment_mode and transaction_number.
        7. Try to find the role according to the farming world like machinery, animals, plants...
        8. NEVER Impute missing values
        Example Output JSON:
          {{"entities": [{{"label":"Organization","id":"25","name":"Groupama","nature":"organisation","transaction_number":"FA52635,"payment_mode":"card","role":"insurance","description":"insurance fee from Groupama"}}]}}
        9. Information come from France in french language
        10. Return the entities in JSON format.

        Question: Now, extract the Organizations for the text below -
      TEXT

      def initialize(model = "mistral-large-latest")
        @content_to_send = { model: model, response_format: { type: 'json_object' }, messages: [{ role: 'system', content: nil }, { role: 'user', content: nil }] }
      end

      def extract_metadata_from_bank_statements(data, instructions = nil)
        return { error: "missing MISTRAL_API_KEY in .env" } if API_KEY.blank?

        return { error: "missing data" } unless data.present?

        return { error: "data parameter is too long : #{data.size.to_s} characters instead of 5000 max" } if data.size > 5000

        # set instructions
        instructions ||= DEFAULT_BS_INSTRUCTION
        @content_to_send[:messages][0][:content] = instructions
        @content_to_send[:messages][1][:content] = data
        # call Mistral API
        # call = RestClient.post BASE_URL, @content_to_send.to_json, headers
        call = RestClient::Request.execute(method: :post, url: BASE_URL, timeout: nil, payload: @content_to_send.to_json, headers: headers)
        response = JSON.parse(call.body).deep_symbolize_keys
        # get content only
        json_response = response[:choices][0][:message][:content]
        JSON.parse(json_response).deep_symbolize_keys
      rescue RestClient::ExceptionWithResponse => err
        { error: err }
      end

      def headers
        { content_type: 'application/json', accept: 'application/json', authorization: "Bearer #{API_KEY}" }
      end

    end
  end
end
