module AnalyticsHelper
  def matomo_tag
    return '' unless Preference.get(:allow_analytics, false, :boolean).value

    piwik_tracking_tag + turbolinks_compatibility_tag
  end

  private
    def turbolinks_compatibility_tag
      tag = <<-HTML
        <script type="text/javascript">
          // [Matomo tracking code goes here]

          // Send Matomo a new event when navigating to a new page using Turbolinks
          // (see https://developer.matomo.org/guides/spa-tracking)
          (function() {
            var previousPageUrl = null;
            document.addEventListener('page:load', function(event) {
              if (previousPageUrl) {
                _paq.push(['setReferrerUrl', previousPageUrl]);
                _paq.push(['setCustomUrl', window.location.href]);
                _paq.push(['setDocumentTitle', document.title]);
                if (event.data && event.data.timing) {
                  _paq.push(['setGenerationTimeMs', event.data.timing.visitEnd - event.data.timing.visitStart]);
                }
                _paq.push(['trackPageView']);
              }
              previousPageUrl = window.location.href;
            });
          })();
        </script>
      HTML
      tag.html_safe
    end
end