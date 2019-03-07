class Student
  include StudentParsingComponents

  def initialize(data)
    @raw = data
    if !data["personRecord"]
      raise StandardError, "Student message does not contain key: personRecord"
    end
    parse(data["personRecord"]["person"])
    # Send parsed data to Patron class, for temporary storage.
    # If this completes the required data, the Patron class will
    # write to ILS
    Patron.store_student(self.as_json)
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
  
end
