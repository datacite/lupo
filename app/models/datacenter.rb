class Datacenter < ApplicationRecord

  validates_presence_of :name, :allocator
end
