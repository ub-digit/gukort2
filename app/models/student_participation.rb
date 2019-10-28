class StudentParticipation
  include StudentParsingComponents
  TEMPORARY_ACCOUNT_EXPIRATION = 2.months
  
  def initialize(data, msg)
    @raw = data
    @msg = msg
    if !data["LadokParticipation"]
      raise StandardError, "Student message does not contain key: LadokParticipation"
    end

    parse(data["LadokParticipation"])
  end

  def process_student_participation
    if @participation_type == "Admission"
      process_admission
    elsif @participation_type == "Registration"
      process_registration
    end
  end

  def process_admission
    if IssuedState.has_issued_state?(@pnr)
      return
    end
    begin
      MQ.generate_cardnumber(@pnr)
      IssuedState.set_issued_state(@pnr)
    rescue => e
      msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
    end
  end

  def process_registration
    begin
      basic_data = Koha.get_basic_data(@pnr)
    rescue => e
      msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      return
    end

    #Does user exist in Koha?
    if basic_data[:borrowernumber]
      process_reg_update(basic_data)
    elsif enough_data_to_create_patron?(@person, @course)
      process_reg_create
    end
  end

  def process_reg_update(basic_data)
    # Person is employed by GU, they should not be updated from a student message
    if is_employed?(basic_data)
      return
    end

    categorycode = basic_data[:categorycode]
    if categorycode != "SY"
      categorycode = generate_categorycode(@course[:org_data])
    end
    
    begin
      Koha.update({
        borrowernumber: basic_data[:borrowernumber],
        patronuserid: @person[:extra][:account],
        # TODO: addresses
        firstname: @person[:name][:firstname],
        surname: @person[:name][:surname],
        phone: @person[:contact][:phone],
        email: @person[:contact][:email],
        categorycode: categorycode
      })
    rescue => e
      msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
    end
    
  end

  def process_reg_create
    # May change to lr
    debarments = ["wr"]
    if !valid_address?(@person)
      debarments << "gna"
    end

    categorycode = generate_categorycode(@course[:org_data])
    if categorycode.blank?
      debarments << "gu"
      categorycode = "EX"
    end
    
    begin
      Koha.create({
        origin: "gukort",
        cardnumber: @pnr,
        personalnumber: @pnr,
        branchcode: "44",
        debarments: debarments.join(","),
        dateexpiry: Time.now + TEMPORARY_ACCOUNT_EXPIRATION,
        patronuserid: @person[:extra][:account],
        # TODO: addresses
        firstname: @person[:name][:firstname],
        surname: @person[:name][:surname],
        phone: @person[:contact][:phone],
        email: @person[:contact][:email],
        categorycode: categorycode,
        lang: "sv-SE",
        messaging_format: @person[:contact][:email].present? ? "email" : nil,
        accept_text: "Biblioteksreglerna accepteras"
      })
    rescue => e
      msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
    end
  end
  
  def as_json(opt = {})
    {
      person: @person.as_json(opt),
      course: @course,
    }
  end

  def parse(data)
    # Person data identical syntactically to Student message
    @person = Student.new(data)
    @person_hash = @person.as_json()
    @pnr = @person_hash[:pnr]
    @participation_type = data["type"]
    @course = parse_course(data["WithinCoursePackages"]["WithinCoursePackage"]["courseSectionRecordSet"]["courseSectionRecord"]["courseSection"])
  end

  def parse_course(data)
    main = parse_course_main(data)
    extra = parse_extension(data["extension"])

    org_data = parse_org_data(data["WithinCoursePackages"]["WithinCoursePackage"]["courseTemplateRecord"],
                              extra[:course_package_code])
    
    {
      main: main,
      extra: extra,
      org_data: org_data
    }
  end

  def parse_org_data(data, package_code)
    if !data.is_kind_of?(Array)
      data = [data]
    end

    package = data.find do |pkg|
      pkg["courseTemplate"]["courseNumber"]["textString"] == package_code
    end

    if !package
      return {}
    end

    template = package["courseTemplate"]

    orgname = nil
    orgunit = nil
    if template["org"]
      orgname = template["org"]["orgName"] ? template["org"]["orgName"]["textString"] : nil
      orgunit = template["org"]["id"] ? template["org"]["id"]["textString"] : nil
    end
    faculty = get_extension(template["extension"], "ResponsibleCommittee")
    
    {
      orgname: orgname,
      orgunit: orgunit,
      faculty: faculty
    }
  end
  
  def parse_course_main(data)
    label = data["label"] ? data["label"]["textString"] : nil
    status = data["status"]
    if data["timeFrame"]
      course_start = Time.parse(data["timeFrame"]["begin"])
      course_end = Time.parse(data["timeFrame"]["end"])
    end
    location = data["location"] ? data["location"]["textString"] : nil

    {
      label: label,
      status: status,
      course_start: course_start,
      course_end: course_end,
      location: location,
    }
  end

  def parse_extension(extensiondata)
    educode = get_extension(extensiondata, "EducationTypeCode")
    course_title = get_extension(extensiondata, "CoursePackageTitle")
    course_package_code = get_extension(extensiondata, "ParentTemplateCode")
    {
      educode: educode,
      course_title: course_title,
      course_package_code: course_package_code
    }
  end

  def get_extension(extensiondata, field_name)
    get_field(extensiondata["extensionField"], field_name)
  end
end
