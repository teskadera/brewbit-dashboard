class SessionEvent < ActiveRecord::Base
  belongs_to :device_session, touch: false
  
  def timestamp=(timestamp)
    self.occurred_at = Time.at(timestamp.to_f / 1000).to_datetime
  end
  
  def timestamp
    self.occurred_at.to_i * 1000
  end
  
  def note=(note)
    self.event_data = { note: note }
  end
  
  def note
    self.event_data[:note]
  end
  
  def summary
    return self.event_data["note"] if self.event_type == "note"

    session_changes = self.event_data.clone
    output_changes = session_changes.delete('output_settings')

    fields = []
      
    session_changes.each do |field_name, field_value|
      fields << "#{field_name.humanize.downcase} = #{translate_field_value(field_name, field_value).to_s}"
    end

    unless output_changes.nil?
      output_changes.each do |os|
        output_index = os.delete('output_index')
        desc = ['left output', 'right output'][output_index]
        action = os.delete('action')
        if action == 'destroy'
          fields << "removed #{desc}"
        else
          os.each do |field_name, field_value|
            fields << "#{desc} #{field_name.humanize.downcase} = #{translate_field_value(field_name, field_value).to_s}"
          end
        end
      end
    end
      
    case self.event_type
    when 'create'
      action = 'Created'
    when 'update'
      action = 'Updated'
    end
      
    "#{action} session (#{fields.join(', ')})"
  end
    
  def translate_field_value(field_name, field_value)
    case field_name
    when 'temp_profile_id'
      begin
        "'" + TempProfile.find(field_value).name + "'"
      rescue
        "'???'"
      end
    when 'setpoint_type'
      ["static", "temp profile"][field_value]
    when 'function'
      ["heating", "cooling", "manual"][field_value]
    when 'temp_profile_completion_action'
      ["'hold last temp'", "'start over'"][field_value]
    when 'temp_profile_start_point'
      if field_value.to_i == -1
        "'current position'"
      else
        "'Step #{field_value.to_i + 1}'"
      end
    when 'static_setpoint'
      field_value.round(1)
    else
      field_value
    end
  end
end
