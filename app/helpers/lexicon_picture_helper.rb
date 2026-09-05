# frozen_string_literal: true

# Renders an <img> for a lexicon-owned agricultural picture (variety,
# production, activity_family icon). Prefers BYTEA streamed from the
# lexicon schema; falls back to a sprockets asset path if provided, and
# silently drops if neither exists — so pages don't 500 on missing icons.
module LexiconPictureHelper
  def lexicon_image_tag(domain, name, fallback: nil, **opts)
    if MasterAgriculturalPicture.extension_for(domain: domain, name: name)
      image_tag(lexicon_picture_path(domain: domain, name: name), **opts)
    elsif fallback
      begin
        image_tag(fallback, **opts)
      rescue Sprockets::Rails::Helper::AssetNotFound,
             Sprockets::Rails::Helper::AssetNotPrecompiled
        ''.html_safe
      end
    else
      ''.html_safe
    end
  end
end
