class PagesController < ApplicationController
  layout "landing"

  def home
    redirect_to dashboard_path if user_signed_in?
  end
end
