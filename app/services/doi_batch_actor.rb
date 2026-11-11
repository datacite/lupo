# frozen_string_literal: true

class DoiBatchActor
  attr_reader :uid, :role_id, :client_id, :provider_id

  def initialize(batch)
    @uid = batch.submitted_by
    @role_id = batch.role_id
    @client_id = batch.client_id
    @provider_id = batch.provider_id
  end

  def client
    return if client_id.blank?

    Client.where(symbol: client_id).where(deleted_at: nil).first
  end

  def provider
    return if provider_id.blank?

    Provider.where(symbol: provider_id).where(deleted_at: nil).first
  end

  def is_admin?
    role_id == "staff_admin"
  end

  def is_admin_or_staff?
    role_id.in?(%w[staff_admin staff_user])
  end
end
