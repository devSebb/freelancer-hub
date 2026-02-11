class PagesController < ApplicationController
  layout "landing"

  def home
    redirect_to dashboard_path if user_signed_in?
  end

  def pricing
    @initial_interval = %w[monthly yearly].include?(params[:interval]) ? params[:interval] : "monthly"
    @recommended_tier =
      if current_user&.current_plan_tier == :starter
        :pro
      else
        :starter
      end
  end
end
