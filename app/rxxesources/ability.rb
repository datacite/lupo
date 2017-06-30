# class Ability
#   include CanCan::Ability
#
#   # To simplify, all admin permissions are linked to the Notification resource
#
#   def initialize(datacentre)
#     datacentre ||= Datacentre.new(:role_name => "ROLE_ALLOCATOR") # Guest datacentre
#     puts "kristina"
#     if datacentre.role_name == "ROLE_ADMIN"
#       can :manage, :all
#     elsif datacentre.role_name == "ROLE_DEV"
#       can :read, :all
#       can [:update, :show], Datacentre, :id => datacentre.id
#     elsif datacentre.role_name == "ROLE_ALLOCATOR"
#       can [:read], Datacentre
#       can [:update, :show], Datacentre, :id => datacentre.id
#     end
#   end
# end
