class Employee
  TEMPORARY_ACCOUNT_EXPIRATION = 2.months

  def initialize(data, msg)
    @raw = data
    @msg = msg
    if !data["personCanonical"]
      raise StandardError, "Employee message does not contain key: personCanonical"
    end
    parse(data["personCanonical"])
  end

  def process_employee
    # If personStatus is DELETE we ignore this message since we
    # do not delete patrons from Koha.
    if @extra[:person_status] == "DELETE"
      @msg.append_response([__FILE__, __method__, __LINE__, "DELETE message ignored"].inspect)
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
    # set as well. If ADDRESS_MANDATORY is set to true.
    debarments = ["wr"]
    if ENV["ADDRESS_MANDATORY"] == "true"
      debarments << "gna"
    end

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
    old_pnr = deep_get(data, ["personnummer", "previousData"])
    pnr_changed = deep_get(data, ["personnummer", "changed"])
    if pnr_changed == "true"
      pnr_changed == true
    else
      pnr_changed = false
    end
    if old_pnr && pnr_changed
      new_pnr = pnr
      pnr = old_pnr
    end
    person_status = deep_get(data, ["personStatus"])
    account = deep_get(data, ["gukonto", "konto"])
    account_status = deep_get(data, ["gukonto", "status"])
    faculty_name = deep_get(data, ["anstallning", "fakultet", "organisationsnamn"])
    faculty_number = deep_get(data, ["anstallning", "fakultet", "organisationsnummer"])
    institution_name = deep_get(data, ["anstallning", "institution", "organisationsnamn"])
    institution_number = deep_get(data, ["anstallning", "institution", "organisationsnummer"])
    last_employment_date = deep_get(data, ["anstallning", "tomDatumSistaAnstallningsperiod", "data"])

    # Add fake date for continous employment
    if !last_employment_date
      last_employment_date = "2099-12-31"
    end
    {
      pnr: pnr,
      new_pnr: new_pnr,
      pnr_changed: pnr_changed,
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
