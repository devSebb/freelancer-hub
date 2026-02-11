class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_client_limit, only: [ :new, :create ]

  def index
    @pagy, @clients = pagy(current_user.clients.order(created_at: :desc), items: 20)
  end

  def show
  end

  def new
    @client = current_user.clients.build
  end

  def create
    @client = current_user.clients.build(client_params)

    if @client.save
      redirect_to @client, notice: t("clients.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: t("clients.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: t("clients.deleted")
  end

  private

  def ensure_client_limit
    return unless current_user.at_limit?(:clients)

    redirect_to pricing_path(limit: :clients), alert: t(
      "billing.limits.messages.clients_total",
      usage: current_user.usage_for(:clients),
      limit: current_user.limit_for(:clients)
    )
  end

  def set_client
    @client = current_user.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone, :company, :language)
  end
end
