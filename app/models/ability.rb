class Ability
  include CanCan::Ability

  # To simplify, all admin permissions are linked to the Notification resource

  def initialize(allocator)
    allocator ||= Allocator.new(:role => "ROLE_ALLOCATOR") # Guest user

    if allocator.role == "ROLE_ADMIN"
      can :manage, :all
    elsif allocator.role == "ROLE_DEV"
      can :read, :all
      can [:update, :show], Allocator, :id => allocator.id
    elsif allocator.role == "ROLE_ALLOCATOR"
      can [:read], Allocator
      can [:update, :show], Allocator, :id => allocator.id
    end
  end
end
