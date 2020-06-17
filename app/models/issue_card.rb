class IssueCard < Issue
  validate do
    (@move_attributes.keys - self.changes_to_save.keys).each do |attr|
      self.errors.add attr, l('activerecord.errors.messages.can_t_be_changed')
    end
    validate_custom_field_values
  end

  def move!(attributes={})
    @move_attributes, @custom_field_attributes = {}, {}
    if attributes[:status_id] && self.status_id.to_s != attributes[:status_id].to_s
      @move_attributes['status_id'] = attributes[:status_id].to_s
    end
    if attributes[:group_key] && attributes[:group_value]
      if attributes[:group_key] == 'custom_field_values'
        group_values = attributes[:group_value].to_s.split(',')
        if self.custom_field_value(group_values[0]) != group_values[1]
          @custom_field_attributes['custom_field_values'] = Hash[*[group_values[0], group_values[1]]]
        end
      else
        if self.attributes[attributes[:group_key]].to_s != attributes[:group_value].to_s
          @move_attributes[attributes[:group_key]] = attributes[:group_value].to_s
        end
      end
    end
    if @move_attributes.any? || @custom_field_attributes.any?
      self.safe_attributes = @move_attributes.merge(@custom_field_attributes)
      self.save!
    end
  end
end
