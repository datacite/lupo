class Datacentre < ApplicationRecord
  self.table_name = "datacentre"
  alias_attribute :allocator_id, :allocator
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  # validates_presence_of :name
  has_and_belongs_to_many :prefixes, class_name: 'Prefix', join_table: "datacentre_prefixes", foreign_key: :prefixes, association_foreign_key: :datacentre
  belongs_to :allocator, class_name: 'Allocator', foreign_key: :allocator
  has_many :datasets


  #  * Increase used quota counter for a datacentre.
  #  *
  #  * Implementation uses HQL update in order to maintain potential concurrent access (i.e. a datacentre using
  #  * concurrently many API clients. Using HQL update makes sure database row level lock will guarantee only one
  #  * client changes the value at the time.
  #  *
  #  * @param forceRefresh the consequence of using HQL update is lack of the value in the instance field.
  #  * Use ForceRefresh.YES to reread the value from database but be aware that refresh() rereads all fields, not
  #  * only doiQuotaUsed so if you have any other changes in the object persist them first.

  def incQuotaUsed
    # adds a day to the quote used it should trigger after each DOI is created
  end

  # /**
  #  * Check if quota exceeded.
  #  *
  #  * Implementation uses HQL select in order to maintain potential concurrent access (i.e. a datacentre using
  #  * concurrently many API clients.
  #  *
  #  * @return true if quota is exceeded
  #  */
  def isQuotaExceeded
    return false if doi_quota_allowed < 0
    true
  end


end
