class Insurance < ActiveRecord::Base
  # String
  def to_s
    "#{[vcard.full_name, vcard.locality].compact.join(', ')} (#{role(:code)})"
  end

  # Vcard
  has_vcards
  accepts_nested_attributes_for :vcard

  def name
    vcard.full_name
  end

  # Role
  validates_presence_of :role
  named_scope :health_care, :conditions => {:role => 'H'}
  named_scope :accident, :conditions => {:role => 'A'}

  def role(format = :db)
    # TODO: should probably use Law model.
    raw = read_attribute(:role)

    # Guard
    return unless raw.present?

    case format
      when :text
        I18n::translate(raw, :scope => 'activerecord.attributes.insurance.role_enum')
      when :code
        I18n::translate(raw, :scope => 'activerecord.attributes.insurance.role_enum_code')
      else
        raw
    end
  end

  # Group
  def members
    return [] if ean_party.blank?

    Insurance.find(:all, :conditions => {:group_ean_party => ean_party})
  end
  
  def group
    return nil if group_ean_party.blank?
    Insurance.find(:first, :conditions => {:ean_party => group_ean_party})
  end

  # Search
  def self.clever_find(query)
    return [] if query.nil? or query.empty?
    
    query_params = {}
    query_params[:query] = "%#{query}%"

    vcard_condition = "(vcards.given_name LIKE :query) OR (vcards.family_name LIKE :query) OR (vcards.full_name LIKE :query)"

    find(:all, :include => [:vcard], :conditions => ["#{vcard_condition}", query_params], :order => 'full_name, family_name, given_name')
  end
end
