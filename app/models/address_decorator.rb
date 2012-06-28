Spree::Address.class_eval do
  belongs_to :user

  attr_accessible :deleted_at, :user_id

  def self.required_fields
    validator = Spree::Address.validators.find{|v| v.kind_of?(ActiveModel::Validations::PresenceValidator)}
    validator ? validator.attributes : []
  end
  
  # can modify an address if it's not been used in an order 
  def editable?
    new_record? || (shipments.empty? && (Spree::Order.where("bill_address_id = ?", self.id).count + Spree::Order.where("bill_address_id = ?", self.id).count <= 1) && Spree::Order.complete.where("bill_address_id = ? OR ship_address_id = ?", self.id, self.id).count == 0)
  end
  
  def can_be_deleted?
    shipments.empty? && Spree::Order.where("bill_address_id = ? OR ship_address_id = ?", self.id, self.id).count == 0
  end
  
  def to_s
    "#{firstname} #{lastname}: #{zipcode}, #{country}, #{state || state_name}, #{city}, #{address1} #{address2}"
  end

  # stole this problematic alias_method_chain from https://github.com/iloveitaly/spree_address_book/blob/af7ceb22ddf9c5c8d63dfbcac7bf8440dffbea1a/app/models/spree/address_decorator.rb

  # as of version 1.1 Spree::Address does not have a custom destroy method
  # if in the future it is added, this may cause issues
  def destroy
    if can_be_deleted?
      super
    else
      update_attribute(:deleted_at, Time.now)
    end
  end
end
