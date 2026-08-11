class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  private

  def switch_locale(&action)
    I18n.with_locale(locale_from_accept_language_header, &action)
  end

  def locale_from_accept_language_header
    preferred = request.env["HTTP_ACCEPT_LANGUAGE"].to_s.scan(/[a-z]{2}/i).first&.downcase
    I18n.available_locales.map(&:to_s).include?(preferred) ? preferred : I18n.default_locale
  end
end
