class Ability
  include CanCan::Ability

  # To simplify, all admin permissions are linked to the Notification resource

  def initialize(user)
    user ||= User.new(nil) # Guest user
    if user.role == "staff_admin"
      can :manage, :all
    elsif user.role == "staff_user"
      can :read, :all
      can :update, :all
    elsif user.role == "member_admin"
      can [:update, :read], Member, :symbol => user.member_id
      can [:create, :update, :read], Datacenter, :allocator => user.member_id
      can [:create, :update, :read], Dataset, :datacentre => user.datacenter_id
      # can [:update, :read], Prefix, :datacentre => user.datacenter_id
      can [:create, :update, :read, :destroy], User, :member_id => user.member_id
    elsif user.role == "member_user"
      can [:read], Member, :symbol => user.member_id
      can [:update, :read], Datacenter, :allocator => user.member_id
      # can [:read], Prefix, :allocator => user.member_id
      can [:read], Dataset, :datacentre => user.member_id
      can [:update, :read], User, :id => user.id
    elsif user.role == "member_user" && Member.find_by(:symbol => user.member_id).member_type == "non_allocating"
      can [:read], Member, :symbol => user.member_id
      can [:read], Datacenter, :allocator => user.member_id
      # can [:read], Prefix, :allocator => user.member_id
      can [:read], Dataset, :datacentre => user.member_id
      can [:update, :read], User, :id => user.id
    elsif user.role == "data_center_admin"
      can [:read, :update], Datacenter, :symbol => user.datacenter_id
      can [:create, :update, :read], Dataset, :datacentre => user.datacenter_id
      can [:create, :update, :read, :destroy], User, :datacenter_id => user.datacenter_id
    elsif user.role == "data_center_user"
      can [:read], Datacenter, :symbol => user.datacenter_id
      can [:read], Dataset, :datacentre => user.datacenter_id
      can [:read], User, :id => user.id
    else
      can [:read], Dataset
    end
  end
end
