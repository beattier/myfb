class Admin::SettingsController < Admin::BaseController  
  def index
    @settings = Setting.all
  end
  
  def update
    params[:settings].each do |input|
      setting = Setting.find(input[0])
      
      value = case(setting.field_type)
      when 'string':        input[1].to_s
      when 'integer':       input[1].to_i
      when 'boolean':       input[1].to_s
      when 'float':         input[1].to_f
      end
      
      setting.update_attribute(:value, value)
    end
    
    flash[:notice] = "Settings have been saved."
    
    redirect_to :action => :index
  end
end