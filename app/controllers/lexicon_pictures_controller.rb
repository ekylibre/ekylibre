# frozen_string_literal: true

# Streams agricultural pictures stored as BYTEA in the lexicon schema.
# Served behind Devise auth, outside the backend rights.yml gate because
# lexicon pictures are shared reference data (variety/production icons),
# not user-scoped.

class LexiconPicturesController < ApplicationController
  before_action :authenticate_user!

  def show
    picture = MasterAgriculturalPicture.lookup(domain: params[:domain], name: params[:name])
    return head :not_found unless picture

    response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
    send_data picture.picture, type: picture.mime_type, disposition: 'inline'
  end
end
