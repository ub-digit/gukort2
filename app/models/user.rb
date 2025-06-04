class User
  TEMPORARY_ACCOUNT_EXPIRATION = 2.months

  def initialize(data, msg)
    @raw = data
    @msg = msg
    if !data["schemas"] || data["schemas"].empty? || !data["schemas"].include?("urn:ietf:params:scim:schemas:core:2.0:User")
      raise StandardError, "User message does not contain schema: urn:ietf:params:scim:schemas:core:2.0:User"
    end
    parse(data)
  end

  def process_user
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
    if @extra[:user_type].blank?
      @msg.append_response([__FILE__, __method__, __LINE__, "User type must be present. Ignored."].inspect)
      return
    end

    if @extra[:user_type] == "Student" && !has_employee_categorycode?(categorycode)
      if categorycode == "SR" || categorycode[0..0] != "S"
        categorycode = "S"
      end
    else
      if (categorycode != "PE" && categorycode[0..0] != "F") || categorycode == "FR" || categorycode == "FX"
        categorycode = "GU"
      end
    end

    begin
      Koha.handle_syncuser({
        borrowernumber: basic_data[:borrowernumber],
        patronuserid: @extra[:account],
        patronstatus: @extra[:account_status],
        categorycode: categorycode,
        firstname: @name[:firstname],
        surname: @name[:surname],
        email: @contact[:email],
        department_name: @extra[:department_name],
        department_number: @extra[:department_number],
        faculty_number: @extra[:faculty_number],
        valid_to: @extra[:valid_to],
        user_type: @extra[:user_type],
        msgtype: "user"
      })
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
    end

  end

  def process_create
    if @extra[:account_status] == "inactive"
      @msg.append_response([__FILE__, __method__, __LINE__, "Inactive user should never be created"].inspect)
      return
    end
    debarments = ["wr"]
    if ENV["ADDRESS_MANDATORY"] == "true"
      debarments << "gna"
    end

    categorycode = "GU"
    if @extra[:user_type] == "Student"
      categorycode = "S"
    end

    begin
      Koha.handle_syncuser({
        origin: "gukort",
        cardnumber: @pnr,
        personalnumber: @pnr,
        branchcode: "44",
        debarments: debarments.join(","),
        dateexpiry: Time.now + TEMPORARY_ACCOUNT_EXPIRATION,
        patronuserid: @extra[:account],
        patronstatus: @extra[:account_status],
        categorycode: categorycode,
        firstname: @name[:firstname],
        surname: @name[:surname],
        email: @contact[:email],
        department_name: @extra[:department_name],
        department_number: @extra[:department_number],
        faculty_number: @extra[:faculty_number],
        valid_to: @extra[:valid_to],
        user_type: @extra[:user_type],
        lang: "sv-SE",
        messaging_format: @contact[:email].present? ? "email" : nil,
        accept_text: "Biblioteksreglerna accepteras",
        msgtype: "user"
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
  end

  def parse_name(data)
    firstname = deep_get(data, ["name", "givenName"])
    surname = deep_get(data, ["name", "familyName"])
    {
      firstname: firstname,
      surname: surname
    }
  end

  def parse_contact(data)
    emails = data["emails"].select {|e| e["primary"]}
    if(emails.empty?)
      return {}
    end
    {
      email: emails.first["value"]
    }
  end

  def parse_extra(data)
    pnr = deep_get(data, ["urn:in:params:scim:schemas:extension:edu:2.0:User", "civicRegistrationNumber"])
    person_status = deep_get(data, ["active"])
    account = deep_get(data, ["userName"])
    account_status = deep_get(data, ["active"])
    if(account_status == true)
      account_status = "active"
    else
      account_status = "inactive"
    end

    # Doc/Staff only
    department_name = deep_get(data, ["urn:in:params:scim:schemas:extension:edu:2.0:User", "departmentName"])
    department_number = deep_get(data, ["urn:in:params:scim:schemas:extension:edu:2.0:User", "departmentId"])
    faculty_number = department_number =~ /^\d\d+$/ ? department_number[0,2] : ""
    institution_name = deep_get(data, ["urn:in:params:scim:schemas:extension:edu:2.0:User", "institutionName"])

    user_type = deep_get(data, ["userType"])
    # Check if user_type (downcase) contains "student", then set user_type to "Student"
    if user_type && user_type.downcase.include?("student")
      user_type = "Student"
    end
    # Student only
    valid_to = deep_get(data, ["urn:in:params:scim:schemas:extension:edu:2.0:User", "validTo"])

    {
      pnr: pnr,
      account: account,
      account_status: account_status,
      department_name: department_name,
      department_number: department_number,
      faculty_number: faculty_number,
      institution_name: institution_name,
      user_type: user_type,
      valid_to: valid_to
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

  def has_employee_categorycode?(categorycode)
    return true if categorycode == "PE"
    return true if categorycode == "GU"
    return true if categorycode == "TJ"
    return true if categorycode == "TN"
    return false if categorycode == "FR"
    return false if categorycode == "FX"
    return true if categorycode[0..0] == "F"
    return false
  end

end  
