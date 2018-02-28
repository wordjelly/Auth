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
    puts "permitted params are:"
    puts "tehse."
    [{:image => [:parent_id,:parent_class]},:id]
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
  attr_accessor :signed_request
   


  ###########################################################
  ##
  ##
  ## VALIDATIONS
  ##
  ##
  ###########################################################
  validates :parent_id, presence: true
  validates :parent_class, presence: true
  validate :parent_id_is_valid_bson


  ###########################################################
  ##
  ##
  ## CALLBACKS
  ##
  ##
  ###########################################################
  before_save do |document|
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
<<<<<<< HEAD
  		BSON::ObjectId.from_string(self.parent_id)
=======
  		BSON::ObjectId.new(self.parent_id)
>>>>>>> 74e43b51642aac911f23f9989f7d008153c48507
  	rescue
  		self.errors.add(:parent_id, "the parent id is not valid")
  	end	
  end

  ############################################################
  ##
  ##
  ## OTHER CUSTOM DEFS.
  ##
  ##
  ############################################################
  def get_signed_request
<<<<<<< HEAD
    Cloudinary::Utils.sign_request({:public_id=>self.id, :timestamp=>Time.now.to_i}, :options=>{:api_key=>Cloudinary.config.api_key, :api_secret=>Cloudinary.config.api_secret})
=======
    Cloudinary::Utils.sign_request({:public_id=>@model.id, :timestamp=>Time.now.to_i}, :options=>{:api_key=>Cloudinary.config.api_key, :api_secret=>Cloudinary.config.api_secret})
>>>>>>> 74e43b51642aac911f23f9989f7d008153c48507
  end

  def verify_signature_from_webhook

  end

end
<<<<<<< HEAD


=======
>>>>>>> 74e43b51642aac911f23f9989f7d008153c48507
git revert --no-commit 02be73319813619a8cd6ccd144bfa33080056f94..HEAD