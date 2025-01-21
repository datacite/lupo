# frozen_string_literal: true

class Ability
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud

    user ||= User.new(nil) # Guest user
    # @user = user

    if user.role_id == "staff_admin"
      can :manage, :all
      cannot %i[new create], Doi do |doi|
        doi.client.blank? ||
          !(
            doi.client.prefixes.where(uid: doi.prefix).first ||
              doi.type == "OtherDoi"
          )
      end
      can :export, :contacts
      can :export, :organizations
      can :export, :repositories
    elsif user.role_id == "staff_user"
      can %i[read read_billing_information read_contact_information read_analytics], :all
    elsif user.role_id == "consortium_admin" && user.provider_id.present?
      can %i[manage read_billing_information read_contact_information], Provider do |provider|
        user.provider_id.casecmp(provider.consortium_id)
      end
      can %i[update read read_billing_information read_contact_information],
          Provider,
          symbol: user.provider_id.upcase
      can %i[manage], ProviderPrefix do |provider_prefix|
        provider_prefix.provider &&
          user.provider_id.casecmp(provider_prefix.provider.consortium_id)
      end
      can %i[manage], Contact
      # TODO limit contact management to consortium
      #   contact.provider &&
      #     (user.provider_id.casecmp(contact.provider.consortium_id) ||
      #     user.provider_id.casecmp(contact.provider_id))
      # end
      can %i[manage transfer read_contact_information], Client do |client|
        client.provider &&
          user.provider_id.casecmp(client.provider.consortium_id)
      end
      can %i[manage], ClientPrefix # , :client_id => user.provider_id

      # if Flipper[:delete_doi].enabled?(user)
      #   can [:manage], Doi, :provider_id => user.provider_id
      # else
      #   can [:read, :update], Doi, :provider_id => user.provider_id
      # end

      can %i[read get_url transfer read_landing_page_results], Doi do |doi|
        user.provider_id.casecmp(doi.provider.consortium_id)
      end
      can %i[read], Doi
      can %i[read], User
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable? ||
          activity.doi.provider &&
            user.provider_id.casecmp(activity.doi.provider.consortium_id)
      end
    elsif user.role_id == "provider_admin" && user.provider_id.present?
      can %i[update read read_billing_information read_contact_information read_analytics],
          Provider,
          symbol: user.provider_id.upcase
      can %i[manage], Contact, provider_id: user.provider_id
      can %i[manage], ProviderPrefix, provider_id: user.provider_id
      can %i[manage read_contact_information], Client, provider_id: user.provider_id
      cannot %i[manage read_contact_information], Client do |client|
        client.provider.role_name.in?(["ROLE_MEMBER"])
      end
      cannot %i[transfer], Client
      can %i[manage], ClientPrefix # , :client_id => user.provider_id

      # if Flipper[:delete_doi].enabled?(user)
      #   can [:manage], Doi, :provider_id => user.provider_id
      # else
      #   can [:read, :update], Doi, :provider_id => user.provider_id
      # end

      can %i[read get_url transfer read_landing_page_results],
          Doi,
          provider_id: user.provider_id
      can %i[read], Doi
      can %i[read], User
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable? || activity.doi.provider_id == user.provider_id
      end
    elsif user.role_id == "provider_user" && user.provider_id.present?
      can %i[read read_billing_information read_contact_information read_analytics],
          Provider,
          symbol: user.provider_id.upcase
      can %i[read], Provider
      can %i[read], ProviderPrefix, provider_id: user.provider_id
      can %i[read read_contact_information read_analytics], Client, provider_id: user.provider_id
      can %i[read], ClientPrefix # , :client_id => user.client_id
      can %i[read], Contact, provider_id: user.provider_id
      can %i[read get_url read_landing_page_results],
          Doi,
          provider_id: user.provider_id
      can %i[read], Doi
      can %i[read], User
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable? || activity.doi.provider_id == user.provider_id
      end
    elsif user.role_id == "client_admin" && user.client.present? && user.client.is_active == "\x01"
      can %i[read], Provider
      can %i[read update read_contact_information read_analytics], Client, symbol: user.client_id.upcase
      can %i[read], ClientPrefix, client_id: user.client_id

      # if Flipper[:delete_doi].enabled?(user)
      #   can [:manage], Doi, :client_id => user.client_id
      # else
      #   can [:read, :update], Doi, :client_id => user.client_id
      # end

      can %i[
        read
        destroy
        update
        register_url
        validate
        undo
        get_url
        get_urls
        read_landing_page_results
      ],
          Doi,
          client_id: user.client_id
      can %i[new create], Doi do |doi|
        doi.client.prefixes.where(uid: doi.prefix).present? ||
          doi.type == "OtherDoi"
      end
      can %i[read], Doi
      can %i[read], User
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable? || activity.doi.client_id == user.client_id
      end
    elsif user.role_id == "client_admin" && user.client.present?
      can %i[read], Provider
      can %i[read read_contact_information read_analytics], Client, symbol: user.client_id.upcase
      can %i[read], ClientPrefix, client_id: user.client_id
      can %i[read], Doi, client_id: user.client_id
      can %i[read], Doi
      can %i[read], User
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable? || activity.doi.client_id == user.client_id
      end
    elsif user.role_id == "client_user" && user.client.present?
      can %i[read], Provider
      can %i[read read_contact_information read_analytics], Client, symbol: user.client_id.upcase
      can %i[read], ClientPrefix, client_id: user.client_id
      can %i[read get_url read_landing_page_results],
          Doi,
          client_id: user.client_id
      can %i[read], Doi
      can %i[read], User
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable? || activity.doi.client_id == user.client_id
      end
    elsif user.role_id == "user"
      can %i[read], Provider
      if user.provider_id.present?
        can %i[update], Provider, symbol: user.provider_id.upcase
      end
      if user.client_id.present?
        can %i[read update], Client, symbol: user.client_id.upcase
      end
      can %i[read], Doi, client_id: user.client_id if user.client_id.present?
      can %i[read get_url], Doi
      can %i[read], User, id: user.id
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable?
      end
    elsif user.role_id == "temporary"
      can %i[read], Provider
      can %i[update read_contact_information], Provider, symbol: "ADMIN" if user.uid == "admin"
      if user.provider_id.present?
        can %i[update read_contact_information], Provider, symbol: user.provider_id.upcase
      end
      if user.client_id.present?
        can %i[read update read_contact_information], Client, symbol: user.client_id.upcase
      end
      can %i[read], Doi, client_id: user.client_id if user.client_id.present?
      can %i[read get_url], Doi
      can %i[read], User, id: user.id
      can %i[read], Phrase
      can %i[read], Activity do |activity|
        activity.doi.findable?
      end
    elsif user.role_id == "anonymous"
      can %i[read get_url], Doi
      can %i[read], Provider
      can %i[read], Activity do |activity|
        activity.doi.findable?
      end
    end
  end
end
