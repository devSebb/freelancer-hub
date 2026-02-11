class SettingsController < ApplicationController
  def show
    @user = current_user
    @billing_plan = @user.current_plan_tier
    @billing_usage = {
      clients: usage_payload_for(:clients),
      proposals: usage_payload_for(:proposals),
      invoices: usage_payload_for(:invoices),
      templates: usage_payload_for(:templates)
    }
    @billing_subscription = @user.active_subscription
    @billing_activating = params[:checkout] == "success" && !@user.pro?
    @show_upgrade_nudge = @billing_plan == :free && near_any_limit?
  end

  def update
    @user = current_user

    if @user.update(settings_params)
      redirect_to settings_path, notice: t("settings.saved")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def usage_payload_for(resource)
    {
      usage: @user.usage_for(resource),
      limit: @user.limit_for(resource)
    }
  end

  def near_any_limit?
    [ :clients, :proposals, :invoices, :templates ].any? do |resource|
      limit = @user.limit_for(resource)
      next false if limit.nil? || limit.zero?

      @user.usage_for(resource) >= (limit - 1)
    end
  end

  def settings_params
    params.require(:user).permit(:name, :business_name, :address, :language, :logo)
  end
end
