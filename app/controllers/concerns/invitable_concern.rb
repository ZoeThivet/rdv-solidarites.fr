# frozen_string_literal: true

module InvitableConcern
  extend ActiveSupport::Concern

  included do
    before_action(
      :store_token_in_session, :redirect_if_invalid_invitation, :redirect_if_logged_in_user_is_not_invited_user,
      if: -> { params[:invitation_token].present? }
    )
  end

  private

  def store_token_in_session
    session[:invitation_token] = params[:invitation_token]
  end

  def redirect_if_invalid_invitation
    return if current_user.present? # we don't check the token if a user is logged in already
    return if invited_user.present?

    delete_token_from_session_and_redirect(t("devise.invitations.invitation_token_invalid"))
  end

  def redirect_if_logged_in_user_is_not_invited_user
    return if current_user.blank? || invited_user.blank?
    return if invited_user == current_user

    delete_token_from_session_and_redirect(t("devise.invitations.current_user_mismatch"))
  end

  def delete_token_from_session_and_redirect(error_msg)
    session.delete(:invitation_token)
    flash[:error] = error_msg
    redirect_to root_path
  end

  def invitation?
    invited_user.present?
  end

  def invited_user
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @invited_user ||= User.find_by_invitation_token(session[:invitation_token], true)
    # rubocop:enable Rails/DynamicFindBy
  end
end
