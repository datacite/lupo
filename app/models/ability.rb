class Ability
  include CanCan::Ability

  # To simplify, all admin permissions are linked to the Notification resource

  def initialize(user)
    user ||= User.new(:role => "anonymous") # Guest user
    if user.role == "staff_admin"
      can :manage, :all
    elsif user.role == "staff_user"
      can :read, :all
    elsif user.role == "member_admin"
      can [:read], Allocator, :symbol => user.symbol
      can [:create, :update, :read], Datacentre, :allocator => user.symbol
      # can [:read], Prefix, :allocator => user.symbol
      can [:create, :update, :show], Dataset, :datacentre => user.symbol
    elsif user.role == "member_user"
      can [:read], Allocator, :symbol => user.symbol
      can [:update, :read], Datacentre, :allocator => user.symbol
      # can [:read], Prefix, :allocator => user.symbol
      # can [:create, :update, :show], Dataset, :allocator => user.symbol
    elsif user.role == "datacentre_admin"
      can [:read, :update], Datacentre, :symbol => user.symbol
      can [:create, :update, :read], Dataset, :datacentre => user.symbol
    elsif user.role == "datacentre_user"
      can [:read], Datacentre, :symbol => user.symbol
      can [:update, :read], Dataset, :datacentre => user.symbol
    end
  end
end
