class Ability
  include CanCan::Ability

  # To simplify, all admin permissions are linked to the Notification resource

  def initialize(user)
    user ||= User.new(:role => "anonymous") # Guest user
    if user.role == "staff_admin"
      can :manage, :all
    elsif user.role == "staff_user"
      can :read, :all
      can :update, :all
    elsif user.role == "member_admin"
      can [:read], Allocator, :symbol => user.member_id
      can [:create, :update, :read], Datacentre, :allocator => user.member_id
      can [:create, :update, :read], Dataset, :datacentre => user.datacenter_id
      # can [:update, :read], Prefix, :datacentre => user.datacenter_id
      can [:create, :update, :read, :destroy], User, :member_id => user.member_id
    elsif user.role == "member_user"
      can [:read], Allocator, :symbol => user.member_id
      can [:update, :read], Datacentre, :allocator => user.member_id
      # can [:read], Prefix, :allocator => user.member_id
      can [:update, :read], Dataset, :datacentre => user.member_id
      can [:update, :read], User, :id => user.id
    elsif user.role == "datacentre_admin"
      can [:read, :create, :update], Datacentre, :symbol => user.datacenter_id
      can [:create, :update, :read], Dataset, :datacentre => user.datacenter_id
      can [:create, :update, :read, :destroy], User, :datacenter_id => user.datacenter_id
    elsif user.role == "datacentre_user"
      can [:read], Datacentre, :symbol => user.datacenter_id
      can [:update, :read], Dataset, :datacentre => user.datacenter_id
      can [:update, :read], User, :id => user.id
    elsif user.role == "anonymous"
      can [:read], Dataset
    end
  end
end
