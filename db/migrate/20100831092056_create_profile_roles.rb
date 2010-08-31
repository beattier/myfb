class CreateProfileRoles < ActiveRecord::Migration
  def self.up

    # Create Profile Table
    create_table :profiles do |t|
      t.references :user

      t.string :real_name
      t.string :location
      t.string :website
      
      t.timestamps
    end
    
    # Create OpenID Tables
    #create_table :open_id_authentication_associations, :force => true do |t|
    #  t.integer :issued, :lifetime
    #  t.string :handle, :assoc_type
    #  t.binary :server_url, :secret
    #end

    #create_table :open_id_authentication_nonces, :force => true do |t|
    #  t.integer :timestamp, :null => false
    #  t.string :server_url, :null => true
    #  t.string :salt, :null => false
    #end
    
    create_table :roles do |t|
      t.column :name, :string
    end
    
    # generate the join table
    create_table :roles_users, :id => false do |t|
      t.column :role_id, :integer
      t.column :user_id, :integer
    end
    
    # Create admin role and user
    admin_role = Role.create(:name => 'admin')
    
    user = User.create do |u|
      u.login = 'admin'
      u.password = u.password_confirmation = 'baseapp'
      u.email = 'nospam@baseapp.local'
    end
    
    user.roles << admin_role


  end

  def self.down
    drop_table :profiles
    #drop_table :open_id_authentication_associations
    #drop_table :open_id_authentication_nonces
    drop_table :roles
    drop_table :roles_users
    
  end
end
