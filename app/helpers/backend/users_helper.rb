module Backend::UsersHelper
  def access_control_list(rights)
    return nil if rights.blank?
    render partial: 'access_control_list', locals: { rights: rights }
  end
end
