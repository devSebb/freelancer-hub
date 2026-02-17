class PagesController < ApplicationController
  layout "landing"

  def home
    redirect_to dashboard_path if user_signed_in?
  end

  def terms
  end

  def pricing
    @initial_interval = %w[monthly yearly].include?(params[:interval]) ? params[:interval] : "monthly"
    @recommended_tier = recommended_tier_for_pricing
  end

  private

  def recommended_tier_for_pricing
    if params[:limit].present?
      # From limit redirect: highlight the tier that addresses the limit (Starter for free, Pro for Starter).
      current_user&.current_plan_tier == :starter ? :pro : :starter
    elsif current_user&.current_plan_tier == :starter
      :pro
    else
      :starter
    end
  end
end
