module StudentParsingComponents
  def is_student?(categorycode)
    return true if ["SH","SE","SS","SP","SM","SA","SK","SY","S"].include?(categorycode)
    return false
  end

  def is_employed?(basic_data, for_time = nil)
    time = for_time ? for_time : Time.now
    if basic_data[:expirationdate] && basic_data[:expirationdate] > time
      return true
    end
    false
  end

  def generate_categorycode(org_data)
    # TODO: Check the types and formats for faculty and orgunit
    nil
  end

  def generate_addresses(address1, address2)
    if has_address?(address2) && !has_address?(address1)
      address1 = address2
      address2 = nil
    end

    address_data = {}
    
    if has_address?(address1)
      address_data.merge!({
        address: [address1[:care_of], address1[:street]].compact.join(" "),
        zipcode: address1[:zip],
        city: address1[:city],
        country: address1[:country]
      })
    end

    if has_address?(address2)
      address_data.merge!({
        b_address: [address2[:care_of], address2[:street]].compact.join(" "),
        b_zipcode: address2[:zip],
        b_city: address2[:city],
        b_country: address2[:country]
      })
    end

    address_data
  end
  
  def enough_data_to_create_patron?(person, course)
    true # TODO: Check!
  end

  def has_address?(address)
    if address && address[:street] && address[:zip] && address[:city]
      return true
    else
      return false
    end
  end

  def local_zip?(address)
    if address &&
        address[:zip] &&
        address[:zip].size == 5 &&
        address[:zip][0] == "4" &&
        address[:zip] != "40530"
      return true
    else
      return false
    end
  end

  def valid_address?(folkbokforing, postadress)
    # Invalid if no address exists
    return false if !has_address?(folkbokforing) && !has_address?(postadress)
    # Invalid if only temporary address outside of GBG area
    return false if !has_address?(folkbokforing) && has_address?(postadress) && !local_zip?(postadress)
    true
  end
  
  def get_value_of_type(data, type_key, value_key, instance_type)
    if !data.is_a?(Array)
      data = [data]
    end
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
