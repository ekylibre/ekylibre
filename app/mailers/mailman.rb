# -*- coding: utf-8 -*-
class Mailman < ActionMailer::Base
  def mailing(expedier, recipient, subject, text, piece = nil)
    # from       expedier
    # recipients recipient
    # subject    subject
    # body       :text=>text
    @text = text
    if piece
      attachments[piece[:filename]] = piece[:body]
      # attachment piece
      # (:content_type => piece.content_type,
      #                  :body => piece.read,
      #                  :filename=>piece.original_filename)
    end
    mail(from: expedier, to: recipient, subject: subject)
  end
end
