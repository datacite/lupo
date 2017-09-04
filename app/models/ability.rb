class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new(nil) # Guest user
    if user.role == "staff_admin"
      can :manage, :all
    elsif user.role == "staff_user"
      can :read, :all
      can :update, :all
    elsif user.role == "provider_admin"
      can [:update, :read], Provider, :symbol => user.provider_id
      can [:create, :update, :read], Client, :allocator => user.allocator
      can [:create, :update, :read], Dataset, :datacentre => user.datacentre
      # can [:update, :read], Prefix, :datacentre => user.client_id
      can [:create, :update, :read, :destroy], User, :provider_id => user.provider_id
    elsif user.role == "provider_user"
      can [:read], Provider, :symbol => user.provider_id
      can [:update, :read], Client, :allocator => user.allocator
      # can [:read], Prefix, :allocator => user.provider_id
      can [:read], Dataset, :datacentre => user.datacentre
      can [:update, :read], User, :id => user.id
    elsif user.role == "client_admin"
      can [:read, :update], Client, :symbol => user.client_id
      can [:create, :update, :read], Dataset, :datacentre => user.datacentre
      can [:create, :update, :read, :destroy], User, :client_id => user.client_id
    elsif user.role == "client_user"
      can [:read], Client, :symbol => user.client_id
      can [:read], Dataset, :datacentre => user.datacentre
      can [:read], User, :id => user.id
    else
      can [:read], Dataset
    end
  end
end
