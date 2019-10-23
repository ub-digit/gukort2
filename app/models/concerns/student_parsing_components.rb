module StudentParsingComponents
  def is_student?(categorycode)
    return true if ["SH","SE","SS","SP","SM","SA","SK","SY"].include?(categorycode)
    return false
  end
  
  def get_value_of_type(data, type_key, value_key, instance_type)
    data.each do |item|
      # Need to put item[type_key] in array to reuse get_instance()
      type_value = get_instance([item[type_key]], instance_type)
      next if !type_value
      return get_value(item, value_key)
    end
    nil
  end
  
  def get_instance_of_type(data, type_key, part_key, instance_type, instance_name)
    if !data.is_a?(Array)
      data = [data]
    end
    data.each do |item|
      # Need to put item[type_key] in array to reuse get_instance()
      type_value = get_instance([item[type_key]], instance_type)
      next if !type_value
      return get_instance(item[part_key], instance_name)
    end
    nil
  end
  
  def get_instance(list, instance_name)
    list.each do |item|
      name = item["instanceIdentifier"]["textString"]
      value = item["instanceValue"]["textString"]
      return value if instance_name == name
    end
    nil
  end

  # For symmetry with get_instance()
  def get_value(item, value_key)
    return nil if !item[value_key]
    return item[value_key]["textString"]
  end

  # For symmetry with get_instance()
  def get_field(list, field_name)
    list.each do |item|
      return item["fieldValue"] if item["fieldName"] == field_name
    end
    nil
  end
end
