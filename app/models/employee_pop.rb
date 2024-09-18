class EmployeePop
  TEMPORARY_ACCOUNT_EXPIRATION = 2.months

  def initialize(data, msg)
    @raw = data
    @msg = msg
    if !data["person"]
      raise StandardError, "Employee message does not contain key: person"
    end
    parse(data["person"])
  end

  def process_employee
    # If personStatus is DELETE we ignore this message since we
    # do not delete patrons from Koha.
    if @extra[:person_status] == "inactive"
      @msg.append_response([__FILE__, __method__, __LINE__, "inactive message ignored"].inspect)
      return
    end

    begin
      basic_data = Koha.get_basic_data(@pnr, @extra[:account])
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      return
    end
    if basic_data[:borrowernumber]
      process_update(basic_data)
    else
      process_create
    end
  end

  def process_update(basic_data)
    categorycode = basic_data[:categorycode]

    # If Working for UB (PE) or already categorised as researcher (F*),
    # do not replace category code, otherwise set GU as generic employee
    if categorycode != "PE" && categorycode[0..0] != "F"
      categorycode = "GU"
    end

    begin
      Koha.update({
        borrowernumber: basic_data[:borrowernumber],
        patronuserid: @extra[:account],
        categorycode: categorycode,
        new_pnr: @new_pnr,
        firstname: @name[:firstname],
        surname: @name[:surname],
        last_employment_date: @extra[:last_employment_date]
      })
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
    end

  end

  def process_create
    # If PNR was not changed, but we have more than one PNR,
    # make sure we use the correct one when creating a new user
    pnr = @pnr
    if !@extra[:pnr_changed] && @new_pnr
      pnr = @new_pnr
    end
    
    if !IssuedState.has_issued_state?(pnr)
      begin
        MQ.generate_cardnumber(pnr)
        IssuedState.set_issued_state(pnr)
      rescue => e
        @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      end
    end

    # Always set WR, and employee data lacks address information, so GNA is
    # set as well.
    debarments = ["wr", "gna"]

    begin
      Koha.create({
        origin: "gukort",
        cardnumber: pnr,
        personalnumber: pnr,
        branchcode: "44",
        debarments: debarments.join(","),
        dateexpiry: Time.now + TEMPORARY_ACCOUNT_EXPIRATION,
        patronuserid: @extra[:account],
        firstname: @name[:firstname],
        surname: @name[:surname],
        phone: @contact[:phone],
        email: @contact[:email],
        categorycode: "GU",
        lang: "sv-SE",
        messaging_format: @contact[:email].present? ? "email" : nil,
        accept_text: "Biblioteksreglerna accepteras",
        last_employment_date: @extra[:last_employment_date]
      })
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
    end
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
    @pnr = @extra[:pnr]
    @new_pnr = @extra[:new_pnr]
  end

  def parse_name(data)
    firstname = deep_get(data, ["name", "given"])
    surname = deep_get(data, ["name", "family"])
    {
      firstname: firstname,
      surname: surname
    }
  end

  def parse_contact(data)
    communication_data = get_communication_data(data)
    email = communication_data[:email]
    phone = communication_data[:phone]
    {
      email: email,
      phone: phone
    }
  end

  def get_account_data(data)
    list_of_credentials = deep_get(data, "securityCredentials")
    # Find one where the id.schemeId is "User-GUKonto". That's the one we want.
    # If we don't find it, or if there is no "id", we just return an empty hash.
    credential = list_of_credentials.find { |c| c["id"] && c["id"]["schemeId"] == "User-GUKonto" } || {}
    account = deep_get(credential, ["id", "value"])
    account_status = deep_get(data, ["status"])
    {
      account: account,
      account_status: account_status
    }
  end

  def get_communication_data(data)
    # Communications are found in a subsection of the affiliations.
    # Get the most recent affiliation and then look for the communication data in that.
    # Inside one affiliation there is a guExtension.communication.TYPE where TYPE is "email" or "phone".
    # This is a list of communications for that TYPE.
    
    # For email:
    # Get the first email ("address") in the list of emails where the "useCode" is "Personal".
    # If there is no email with "useCode" "Personal", get the first email in the list.
    
    # For phone:
    # Get the first phone number ("formattedNumber") in the list of phones where the "useCode" is "Mobile".
    # If there is no phone with "useCode" "Mobile", try "Work".
    # otherwise get the first phone in the list.
    most_recent_affiliation = get_most_recent_affiliation(data)

    # First look for email
    list_of_emails = deep_get(most_recent_affiliation, ["guExtension", "communication", "email"]) || []
    email = list_of_emails.find { |e| e["useCode"] == "Personal" }
    if !email
      email = list_of_emails.first
    end
    # If we found an email, get the "address" field.
    found_email = nil
    if email
      found_email = deep_get(email, ["address"])
    end
    
    # Then look for phone
    list_of_phones = deep_get(most_recent_affiliation, ["guExtension", "communication", "phone"]) || []
    phone = list_of_phones.find { |p| p["useCode"] == "Mobile" }
    if !phone
      phone = list_of_phones.find { |p| p["useCode"] == "Work" }
    end
    if !phone
      phone = list_of_phones.first
    end
    found_phone = nil
    if phone
      found_phone = deep_get(phone, ["formattedNumber"])
    end

    {
      email: found_email,
      phone: found_phone
    }
  end

  def get_most_recent_affiliation(data)
    list_of_affiliations = deep_get(data, ["affiliations"])
    # Now we need to find the most recent affiliation.
    # Each affiliation can have an "endDate" which we can use to compare.
    # The "endDate" may be missing, in which case we assume it is still active.
    # A missing "endDate" is always more recent than a present "endDate".
    # Start by replacing all missing "endDate" with a date far into the future (9999-12-31).
    # Then sort the list by "endDate" and pick the first one.
    # If the list is empty, we return an empty hash.
    list_of_affiliations.each do |affiliation|
      if !affiliation["endDate"]
        affiliation["endDate"] = "9999-12-31"
      end
    end
    list_of_affiliations.sort_by { |a| a["endDate"] }.first || {}
  end

  def get_last_employment_date(data)
    most_recent_affiliation = get_most_recent_affiliation(data)
    # The "endDate" is the last day of employment.
    # If the "endDate" is "9999-12-31", replace it with "2099-12-31" to make it follow the previous logic.
    if most_recent_affiliation["endDate"] == "9999-12-31"
      return "2099-12-31"
    end
    most_recent_affiliation["endDate"]
  end

  def parse_extra(data)
    # This could be both a Legal-Samordningsnummer or a Legal-Personnummer
    # For the moment we just use the value regardless of type
    pnr = deep_get(data, ["legalId", "value"])
    # There is no way to know if the pnr is changed, so we just treat it as always changed
    # This will cause the system to replace the pnr in Koha, and if it is not changed
    # the system will replace it with the same value.
    new_pnr = pnr
    account_data = get_account_data(data)
    # "active"/"inactive"
    person_status = account_data[:account_status]
    account = account_data[:account]
    account_status = account_data[:account_status]
    # faculty_name = deep_get(data, ["anstallning", "fakultet", "organisationsnamn"])
    # faculty_number = deep_get(data, ["anstallning", "fakultet", "organisationsnummer"])
    # institution_name = deep_get(data, ["anstallning", "institution", "organisationsnamn"])
    # institution_number = deep_get(data, ["anstallning", "institution", "organisationsnummer"])
    # last_employment_date = deep_get(data, ["anstallning", "tomDatumSistaAnstallningsperiod", "data"])

    # Ignore faculty and institution for now, just define them as nil
    faculty_name = nil
    faculty_number = nil
    institution_name = nil
    institution_number = nil

    last_employment_date = get_last_employment_date(data)

    # Add fake date for continous employment
    if !last_employment_date
      last_employment_date = "2099-12-31"
    end
    {
      pnr: pnr,
      new_pnr: new_pnr,
      pnr_changed: true,
      person_status: person_status,
      account: account,
      account_status: account_status,
      faculty_name: faculty_name,
      faculty_number: faculty_number,
      institution_name: institution_name,
      institution_number: institution_number,
      last_employment_date: last_employment_date
    }
  end

  def deep_get(data, path)
    d = data
    path.each do |p|
      return nil if !d[p]
      if d[p].kind_of?(Array)
        d = d[p].first
      else
        d = d[p]
      end
    end
    if d.kind_of?(Array)
      return d.first
    end
    d
  end
end  
