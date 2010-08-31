class Announcement < ActiveRecord::Base
  scope :active, lambda { 
    where("starts_at <= ? AND ends_at >= ?", Time.now.utc, Time.now.utc) 
  }    
  scope :since, lambda { |hide_time|  
    where("updated_at > ? OR starts_at > ?", hide_time.utc, hide_time.utc) if hide_time
  }
  
  def self.display(hide_time)
    active.since(hide_time)
  end

end
