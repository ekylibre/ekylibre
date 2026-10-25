# frozen_string_literal: true

# == Table: master_agricultural_pictures
#
#  domain    :string  not null
#  extension :string  not null
#  id        :integer not null, primary key
#  name      :string  not null
#  picture   :binary  not null
#
# Read-only reference data sourced from the lexicon schema. Replaces the
# legacy filesystem assets under app/assets/images/{varieties,productions,
# activity_families}: any new lexicon variety/production lands without a
# corresponding precompiled asset, which raised AssetNotFound in production
# (e.g. /first-run/activities/edit crashing on "varieties/alpaca.jpg").

class MasterAgriculturalPicture < LexiconRecord
  include Lexiconable

  scope :for_domain_and_name, ->(domain, name) { where(domain: domain, name: name) }

  # Returns the extension if a picture exists for (domain, name), nil otherwise.
  # Memoized per-process: lexicon data is read-only at runtime (rebuilt only by
  # `rake lexicon:load`), so a class-level cache is safe and avoids hammering
  # the DB when many images are rendered on a single page.
  def self.extension_for(domain:, name:)
    @extension_cache ||= {}
    key = [domain.to_s, name.to_s]
    return nil if @extension_cache[key] == :__missing__

    @extension_cache[key] ||= where(domain: domain, name: name).pluck(:extension).first || :__missing__
    @extension_cache[key] == :__missing__ ? nil : @extension_cache[key]
  end

  def self.lookup(domain:, name:)
    find_by(domain: domain, name: name)
  end

  def mime_type
    Mime::Type.lookup_by_extension(extension)&.to_s || "image/#{extension}"
  end
end
