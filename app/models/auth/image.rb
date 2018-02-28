class Auth::Image

  include Mongoid::Document
  include Auth::Concerns::OwnerConcern


  ###########################################################
  ##
  ##
  ##
  ## CLASS METHODS
  ##
  ##
  ## 
  ###########################################################
  ## the parent id is the id of the object in which the image is uploaded.
  ## it need not exist. but has to be a valid bson object id.
  def self.permitted_params
    [{:image => [:_id,:parent_id,:parent_class,:active,:timestamp,:public_id]},:id]
  end


  ###########################################################
  ##
  ##
  ##
  ## ATTRIBUTES
  ##
  ##
  ##
  ###########################################################  
  field :parent_id, type: String
  field :parent_class, type: String
  field :active, type: Boolean, default: true  
  attr_accessor :signed_request
  attr_accessor :timestamp
  attr_accessor :public_id
   


  ###########################################################
  ##
  ##
  ## VALIDATIONS
  ##
  ##
  ###########################################################
  validates :parent_id, presence: true
  validates :parent_class, presence: true
  validates :timestamp, numericality: { only_integer: true, greater_than_or_equal_to: Time.now.to_i - 30 }, if: Proc.new{|c| c.new_record?}
  validate :public_id_equals_id, if: Proc.new{|c| c.new_record?}


  ###########################################################
  ##
  ##
  ## CALLBACKS
  ##
  ##
  ###########################################################
  after_create do |document|
    document.signed_request = get_signed_request
  end


  ###########################################################
  ##
  ##
  ## CUSTOM VALIDATION DEFS.
  ##
  ##
  ###########################################################
  def parent_id_is_valid_bson
  	begin
  		BSON::ObjectId.from_string(self.parent_id)
  	rescue
  		self.errors.add(:parent_id, "the parent id is not valid")
  	end	
  end

  def public_id_equals_id
    self.errors.add(:public_id, "the public id and object id are not equal") if (self.id.to_s != self.public_id)
  end

  ############################################################
  ##
  ##
  ## OTHER CUSTOM DEFS.
  ##
  ##
  ############################################################
  def get_signed_request

    Cloudinary::Utils.sign_request({:public_id => self.id.to_s,:timestamp=> self.timestamp, :callback => "http://widget.cloudinary.com/cloudinary_cors.html"}, :options=>{:api_key=>Cloudinary.config.api_key, :api_secret=>Cloudinary.config.api_secret})

  end

  ## rendered in create, in the authenticated_controller.
  def text_representation
    self.signed_request[:signature].to_s
  end

end
