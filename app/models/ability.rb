class Ability
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud

    user ||= User.new(nil) # Guest user
    # @user = user

    if user.role_id == "staff_admin"
      can :manage, :all
      cannot [:new, :create], Doi do |doi|
        doi.client.blank? || !(doi.client.prefixes.where(prefix: doi.prefix).first || doi.client.symbol.downcase.start_with?("crossref.") || doi.client.symbol.downcase.start_with?("medra."))
      end
    elsif user.role_id == "staff_user"
      can :read, :all
    elsif user.role_id == "provider_admin" && user.provider_id.present?
      can [:update, :read, :read_billing_information], Provider, :symbol => user.provider_id.upcase
      can [:read], Provider
      can [:manage], ProviderPrefix, :provider_id => user.provider_id
      can [:manage], Client,:provider_id => user.provider_id
      can [:manage], ClientPrefix #, :client_id => user.provider_id

      # if Flipper[:delete_doi].enabled?(user)
      #   can [:manage], Doi, :provider_id => user.provider_id
      # else
      #   can [:read, :update], Doi, :provider_id => user.provider_id
      # end

      can [:read, :transfer, :read_landing_page_results], Doi, :provider_id => user.provider_id
      can [:read], Doi do |doi|
        doi.findable?
      end
      can [:read], User
      can [:read], Phrase
      can [:read], Activity do |activity|
        activity.doi.findable? || activity.doi.provider_id == user.provider_id
      end
    elsif user.role_id == "provider_user" && user.provider_id.present?
      can [:read, :read_billing_information], Provider, :symbol => user.provider_id.upcase
      can [:read], Provider
      can [:read], ProviderPrefix, :provider_id => user.provider_id
      can [:read], Client, :provider_id => user.provider_id
      can [:read], ClientPrefix#, :client_id => user.client_id
      can [:read, :read_landing_page_results], Doi, :provider_id => user.provider_id
      can [:read], Doi do |doi|
        doi.findable?
      end
      can [:read], User
      can [:read], Phrase
      can [:read], Activity do |activity|
        activity.doi.findable? || activity.doi.provider_id == user.provider_id
      end
    elsif user.role_id == "client_admin" && user.client_id.present?
      can [:read, :update], Client, :symbol => user.client_id.upcase
      can [:read], ClientPrefix, :client_id => user.client_id

      # if Flipper[:delete_doi].enabled?(user)
      #   can [:manage], Doi, :client_id => user.client_id
      # else
      #   can [:read, :update], Doi, :client_id => user.client_id
      # end

      can [:read, :destroy, :update, :register_url, :validate, :undo, :get_url, :get_urls, :read_landing_page_results], Doi, :client_id => user.client_id
      can [:new, :create], Doi do |doi| 
        doi.client.prefixes.where(prefix: doi.prefix).present? || doi.client.symbol.downcase.start_with?("crossref.") || doi.client.symbol.downcase.start_with?("medra.")
      end
      can [:read], Doi do |doi|
        doi.findable?
      end
      can [:read], User
      can [:read], Phrase
      can [:read], Activity do |activity|
        activity.doi.findable? || activity.doi.client_id == user.client_id
      end
    elsif user.role_id == "client_user" && user.client_id.present?
      can [:read], Client, :symbol => user.client_id.upcase
      can [:read], ClientPrefix, :client_id => user.client_id
      can [:read, :read_landing_page_results], Doi, :client_id => user.client_id
      can [:read], Doi do
        |doi| doi.findable?
      end
      can [:read], User
      can [:read], Phrase
      can [:read], Activity do |activity|
        activity.doi.findable? || activity.doi.client_id == user.client_id
      end
    elsif user.role_id == "user"
      can [:read, :update], Provider, :symbol => user.provider_id.upcase if user.provider_id.present?
      can [:read, :update], Client, :symbol => user.client_id.upcase if user.client_id.present?
      can [:read], Doi, :client_id => user.client_id if user.client_id.present?
      can [:read], Doi do |doi|
        doi.findable?
      end
      can [:read], User, :id => user.id
      can [:read], Phrase
      can [:read], Activity do |activity|
        activity.doi.findable?
      end
    elsif user.role_id == "anonymous"
      can [:read], Doi do |doi|
        doi.findable?
      end
      can [:read], Provider
      can [:read], Activity do |activity|
        activity.doi.findable?
      end
    end
  end
end
