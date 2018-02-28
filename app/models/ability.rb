class Ability
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    user ||= User.new(nil) # Guest user
    @user = user

    if user.role_id == "staff_admin"
      can :manage, :all
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
      can [:manage], Doi, :provider_id => user.provider_id

      can [:read], User
      can [:read], Phrase
    elsif user.role_id == "provider_user" && user.provider_id.present?
      can [:read], Provider, :symbol => user.provider_id.upcase
      can [:read], ProviderPrefix, :provider_id => user.provider_id
      can [:read], Client, :provider_id => user.provider_id
      can [:read], ClientPrefix#, :client_id => user.client_id
      can [:read], Doi, :provider_id => user.provider_id
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
      can [:manage, :register_url], Doi, :client_id => user.client_id

      can [:read], User
      can [:read], Phrase
    elsif user.role_id == "client_user" && user.client_id.present?
      can [:read], Client, :symbol => user.client_id.upcase
      can [:read], ClientPrefix, :client_id => user.client_id
      can [:read], Doi, :client_id => user.client_id
      can [:read], User
      can [:read], Phrase
    elsif user.role_id == "user"
      can [:read, :update], Provider, :symbol => user.provider_id.upcase if user.provider_id.present?
      can [:read, :update], Client, :symbol => user.client_id.upcase if user.client_id.present?
      can [:read], Doi
      can [:read], User, :id => user.id
      can [:read], Phrase
    end
  end
end
