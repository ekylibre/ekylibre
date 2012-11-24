class Mailman < ActionMailer::Base

  def message(expedier, recipient, title, text, uploaded_file=nil)
    from       expedier
    recipients recipient
    subject    title
    body       :text=>text
    if uploaded_file
      attachment uploaded_file
# (:content_type => uploaded_file.content_type,
#                  :body => uploaded_file.read,
#                  :filename=>uploaded_file.original_filename)
    end
  end

end
