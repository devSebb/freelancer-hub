class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Make ApplicationHelper (and IconHelper) available in every view
  helper ApplicationHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  private

  def set_locale
    I18n.locale = user_locale || I18n.default_locale
  end

  def user_locale
    current_user&.language&.to_sym
  end
end
