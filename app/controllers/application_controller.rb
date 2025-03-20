class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :set_locale
  helper_method :current_user

  private

  def sign_in(user)
    session[:user_id] = user.id
  end

  def sign_out
    session[:user_id] = nil
  end

  def current_user
    @current_user ||=
      if session[:user_id]
        User.find_by(id: session[:user_id])
      end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
