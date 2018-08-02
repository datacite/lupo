class Ability
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud

    user ||= User.new(nil) # Guest user
    @user = user

    if user.role_id == "staff_admin"
      can :manage, :all
      # can :manage, [Provider, ProviderPrefix, Client, ClientPrefix, Prefix, Phrase, User]
      # can [:read, :transfer, :set_state, :set_minted, :set_url, :delete_test_dois], Doi
      cannot [:new, :create], Doi do |doi|
        !doi.client.prefixes.where(prefix: doi.prefix).first
      end
    elsif user.role_id == "staff_user"
      can :read, :all
    elsif user.role_id == "provider_admin" && user.provider_id.present?
      can [:update, :read], Provider, :symbol => user.provider_id.upcase
      can [:manage], ProviderPrefix, :provider_id => user.provider_id
      can [:manage], Client,:provider_id => user.provider_id
      can [:manage], ClientPrefix#, :client_id => user.provider_id

      # if Flipper[:delete_doi].enabled?(user)
      #   can [:manage], Doi, :provider_id => user.provider_id
      # else
      #   can [:read, :update], Doi, :provider_id => user.provider_id
      # end
      can [:read, :transfer], Doi, :provider_id => user.provider_id
      can [:read], Doi do |doi| 
        doi.findable?
      end
      can [:read], User
      can [:read], Phrase
    elsif user.role_id == "provider_user" && user.provider_id.present?
      can [:read], Provider, :symbol => user.provider_id.upcase
      can [:read], ProviderPrefix, :provider_id => user.provider_id
      can [:read], Client, :provider_id => user.provider_id
      can [:read], ClientPrefix#, :client_id => user.client_id
      can [:read], Doi, :provider_id => user.provider_id
      can [:read], Doi do |doi| 
        doi.findable?
      end
      can [:read], User
      can [:read], Phrase
    elsif user.role_id == "client_admin" && user.client_id.present?
      can [:read, :update], Client, :symbol => user.client_id.upcase
      can [:read], ClientPrefix, :client_id => user.client_id

      # if Flipper[:delete_doi].enabled?(user)
      #   can [:manage], Doi, :client_id => user.client_id
      # else
      #   can [:read, :update], Doi, :client_id => user.client_id
      # end
      can [:read, :update, :destroy, :register_url, :get_url, :get_urls], Doi, :client_id => user.client_id
      can [:new, :create], Doi do |doi|
        doi.client_id == user.client_id && doi.client.prefixes.where(prefix: doi.prefix).first
      end
      can [:read], Doi do |doi|
        doi.findable?
      end
      can [:read], User
      can [:read], Phrase
    elsif user.role_id == "client_user" && user.client_id.present?
      can [:read], Client, :symbol => user.client_id.upcase
      can [:read], ClientPrefix, :client_id => user.client_id
      can [:read], Doi, :client_id => user.client_id
      can [:read], Doi do
        |doi| doi.findable?
      end
      can [:read], User
      can [:read], Phrase
    elsif user.role_id == "user"
      can [:read, :update], Provider, :symbol => user.provider_id.upcase if user.provider_id.present?
      can [:read, :update], Client, :symbol => user.client_id.upcase if user.client_id.present?
      can [:read], Doi, :client_id => user.client_id if user.client_id.present?
      can [:read], Doi do |doi| 
        doi.findable?
      end
      can [:read], User, :id => user.id
      can [:read], Phrase
    elsif user.role_id == "anonymous"
      can [:read], Doi do |doi|
        doi.findable?
      end
    end
  end
end
