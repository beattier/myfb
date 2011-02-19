require 'aasm_roles'
class User < ActiveRecord::Base
  include AasmRoles
  
  devise :database_authenticatable, :recoverable, :registerable, :rememberable

  # Relations
  has_and_belongs_to_many :roles
  has_one :profile
  
  # Hooks
  after_create :create_profile, :register!
  
  attr_accessible :login, :email, :name, :password, :password_confirmation, :identity_url

  before_validation(:set_default, :on => :create)
  
  def admin?
    has_role?(:admin)
  end
  
  def has_role?(role)
    role_symbols.include?(role.to_sym) || role_symbols.include?(:admin)
  end
  
  def role_symbols
    @role_symbols ||= roles.map {|r| r.name.underscore.to_sym }
  end

  def openid_login?
    !identity_url.blank? #|| (AppConfig.enable_facebook_auth && !facebook_id.blank?)
  end

  def twitter_login?
    !twitter_token.blank? && !twitter_secret.blank?
  end
  
  def not_using_openid?
    !openid_login?
  end
  
  def normalize_identity_url
    self.identity_url = OpenIdAuthentication.normalize_url(identity_url) if openid_login?
  rescue
    errors.add_to_base("Invalid OpenID URL")
  end
  
  def self.find_for_authentication(conditions)
    conditions = ["login = ? or email = ?", conditions[authentication_keys.first], conditions[authentication_keys.first]]
    # raise StandardError, conditions.inspect
    super
  end  

  protected


  def password_required?
    return false if openid_login?
    return false if twitter_login?
    (encrypted_password.blank? || !password.blank?)
  end

  
  def create_profile
    # Give the user a profile
    self.profile = Profile.create    
  end
  
  private
  
  def set_default

  end
  
end
