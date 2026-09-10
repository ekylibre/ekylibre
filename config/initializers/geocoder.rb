if Rails.env.test?
  # `:test` est le lookup intégré de Geocoder : il rend des résultats en mémoire
  # et ne sort jamais sur le réseau.
  #
  # Sans lui, la suite tombe dans la branche `else` ci-dessous et interroge
  # Nominatim à chaque enregistrement d'adresse postale
  # (EntityAddress#geolocate_address, en before_save). Nominatim limite le débit
  # et refuse les User-Agent génériques comme celui configuré plus bas :
  # mesuré sur une exécution complète, 398 réponses « 429 Too Many Requests »,
  # autant d'allers-retours réseau, et un résultat qui dépend de l'humeur du
  # service. Aucun test n'assert sur un géocodage.
  Geocoder.configure(
    lookup: :test,
    ip_lookup: :test,
    units: :km,
    distances: :linear
  )
  # Pas de résultat par défaut : c'est déjà ce que la suite obtenait, les appels
  # étant rate-limités. Un test qui aurait besoin d'une position peut poser son
  # propre stub avec Geocoder::Lookup::Test.add_stub.
  Geocoder::Lookup::Test.set_default_stub([])
elsif Rails.env.production?
  Geocoder.configure(
    # Geocoding options
    # timeout: 3,                 # geocoding service timeout (secs)
    lookup: :google,         # name of geocoding service (symbol)
    # ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
    # language: :en,              # ISO-639 language code
    use_https: true,           # use HTTPS for lookup requests? (if supported)
    # http_proxy: nil,            # HTTP proxy server (user:pass@host:port)
    # https_proxy: nil,           # HTTPS proxy server (user:pass@host:port)
    api_key: ENV['GOOGLE_MAPS_API_KEY'],               # API key for geocoding service
    # cache: nil,                 # cache object (must respond to #[], #[]=, and #del)
    # cache_prefix: 'geocoder:',  # prefix (string) to use for all cache keys

    # Exceptions that should not be rescued by default
    # (if you want to implement custom error handling);
    # supports SocketError and Timeout::Error
    # always_raise: [],

    # Calculation options
    units: :km,                 # :km for kilometers or :mi for miles
    distances: :linear          # :spherical or :linear
  )
else
  Geocoder.configure(
    # Geocoding options
    timeout: 3,                 # geocoding service timeout (secs)
    lookup: :nominatim,         # name of geocoding service (symbol)
    language: :fr,              # ISO-639 language code
    use_https: true,           # use HTTPS for lookup requests? (if supported)
    # Calculation options
    units: :km,                # :km for kilometers or :mi for miles
    distances: :linear,         # :spherical or :linear
    http_headers: { "User-Agent" => "your contact info" }
  )
end