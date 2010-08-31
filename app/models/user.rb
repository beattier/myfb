class User < ActiveRecord::Base
  devise :database_authenticatable, :http_authenticatable, :recoverable, :registerable, :rememberable

  # Relations
  has_and_belongs_to_many :roles
  has_one :profile
  
  # Hooks
  after_create :create_profile
  
  attr_accessible :login, :email, :name, :password, :password_confirmation, :identity_url
  
end
