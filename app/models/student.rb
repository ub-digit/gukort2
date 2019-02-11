class Student
  def initialize(data)
    @raw = data
    if !data["personRecord"]
      raise StandardError, "Student message does not contain key: personRecord"
    end
    parse(data["personRecord"]["person"])
  end

  def as_json(opt = {})
    {
      name: @name,
      address1: @addr1,
      address2: @addr2,
      contact: @contact,
      extra: @extra
    }
  end
  
  def parse(data)
    @name = parse_name(data["name"])
    @addr1 = parse_address(data["address"], "POSTADRESS")
    @addr2 = parse_address(data["address"], "FOLKBOKFORINGSADRESS")
    @contact = parse_contact(data["contactinfo"])
    @extra = parse_extension(data["extension"])
  end

  def parse_extension(extensiondata)
    pnr = get_extension(extensiondata, "PersonIdentityNumber")
    account = get_extension(extensiondata, "StudentAccountName")
    account_email = get_extension(extensiondata, "StudentAccountEmail")

    # Doktorand
    account2 = get_extension(extensiondata, "DocAccountName")
    account_email2 = get_extension(extensiondata, "DocAccountEmail")
    # Also DeceasedFlag and ProtectedIdentifyFlag which will be ignored
    {
      pnr: pnr,
      account: account,
      account_email: account_email,
      account2: account2,
      account_email2: account_email2
    }
  end
  
  def parse_contact(contactdata)
    phone = get_contact(contactdata, "TelephonePrimary")
    email = get_contact(contactdata, "EmailPrimary")
    {
      phone: phone,
      email: email
    }
  end
  
  def parse_address(addressdata, addr_type)
    care_of = get_address(addressdata, addr_type, "CareOf")
    street = get_address(addressdata, addr_type, "NonfieldedStreetAddress1")
    zip = get_address(addressdata, addr_type, "Postcode")
    city = get_address(addressdata, addr_type, "City")
    country = get_address(addressdata, addr_type, "Country")
    {
      care_of: care_of,
      street: street,
      zip: zip,
      city: city,
      country: country
    }
  end
  
  def parse_name(namedata)
    firstname = get_name(namedata, "FullName", "First")
    surname = get_name(namedata, "FullName", "Surname")
    {
      firstname: firstname,
      surname: surname
    }
  end

  def get_name(namedata, instance_type, instance_name)
    # Need to put namedata in array to reuse get_instance_of_type()
    get_instance_of_type([namedata], "nameType", "partName", instance_type, instance_name)
  end
  
  def get_address(addressdata, instance_type, instance_name)
    get_instance_of_type(addressdata, "addressType", "addressPart", instance_type, instance_name)
  end

  def get_contact(contactdata, instance_type)
    get_value_of_type(contactdata, "contactinfoType", "contactinfoValue", instance_type)
  end

  def get_extension(extensiondata, field_name)
    get_field(extensiondata["extensionField"], field_name)
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
