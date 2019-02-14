class Employee

  def initialize(data)
    @raw = data
    if !data["personCanonical"]
      raise StandardError, "Employee message does not contain key: personCanonical"
    end
    parse(data["personCanonical"])
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
    @name = parse_name(data)
    @contact = parse_contact(data)
    @extra = parse_extra(data)
  end

  def parse_name(data)
    firstname = deep_get(data, ["fornamn", "data"])
    surname = deep_get(data, ["efternamn", "data"])
    {
      firstname: firstname,
      surname: surname
    }
  end

  def parse_contact(data)
    email = deep_get(data, ["epost", "epostadress", "adress"])
    phone = deep_get(data, ["telefon", "telefonnummer", "nummer"])
    {
      email: email,
      phone: phone
    }
  end

  def parse_extra(data)
    pnr = deep_get(data, ["personnummer", "data"])
    account = deep_get(data, ["gukonto", "konto"])
    account_status = deep_get(data, ["gukonto", "status"])
    faculty_name = deep_get(data, ["anstallning", "fakultet", "organisationsnamn"])
    faculty_number = deep_get(data, ["anstallning", "fakultet", "organisationsnummer"])
    institution_name = deep_get(data, ["anstallning", "institution", "organisationsnamn"])
    institution_number = deep_get(data, ["anstallning", "institution", "organisationsnummer"])
    {
      pnr: pnr,
      account: account,
      account_status: account_status,
      faculty_name: faculty_name,
      faculty_number: faculty_number,
      institution_name: institution_name,
      institution_number: institution_number
    }
  end

  def deep_get(data, path)
    d = data
    path.each do |p|
      return nil if !d[p]
      d = d[p]
    end
    d
  end
end  
