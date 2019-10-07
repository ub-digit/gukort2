class StudentParticipation
  include StudentParsingComponents

  def initialize(data)
    @raw = data
    if !data["LadokParticipation"]
      raise StandardError, "Student message does not contain key: LadokParticipation"
    end

    parse(data["LadokParticipation"])

    #student = self.as_json
    #pp student extra pnr
    my_student = @person
    pp "EXTRA EXTRA READ ALL ABOUT IT"
    pnr = my_student.extra[:pnr]
    pp pnr
    bdata = Patron.get_basic_data(pnr)
    pp bdata[:uniq]
    pp bdata[:borrowernumber]
    pp bdata[:category_code]
    # /personCanonical/anstallning/tomDatumSistaAnstallningsperiod/changed
    pp bdata[:end_date_of_last_employment]
    pp "=============================>>>>"

    #Patron.get_basic_data(pnr)

    # Send parsed data to Patron class, for temporary storage.
    # If this completes the required data, the Patron class will
    # write to ILS
    ##Patron.store_student_participation(self.as_json)
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
    @participation_type = data["type"]
    @course = parse_course(data["courseSectionRecordSet"]["courseSectionRecord"]["courseSection"])
  end

  def parse_course(data)
    main = parse_course_main(data)
    extra = parse_extension(data["extension"])
    {
      main: main,
      extra: extra,
    }
  end

  def parse_course_main(data)
    label = data["label"] ? data["label"]["textString"] : nil
    status = data["status"]
    if data["org"]
      orgname = data["org"]["orgName"] ? data["org"]["orgName"]["textString"] : nil
      orgunit = data["org"]["orgName"] ? data["org"]["orgUnit"]["textString"] : nil
    end
    if data["timeFrame"]
      course_start = Time.parse(data["timeFrame"]["begin"])
      course_end = Time.parse(data["timeFrame"]["end"])
    end
    location = data["location"] ? data["location"]["textString"] : nil

    {
      label: label,
      status: status,
      orgname: orgname,
      orgunit: orgunit,
      course_start: course_start,
      course_end: course_end,
      location: location,
    }
  end

  def parse_extension(extensiondata)
    educode = get_extension(extensiondata, "EducationTypeCode")
    course_title = get_extension(extensiondata, "CoursePackageTitle")

    {
      educode: educode,
      course_title: course_title,
    }
  end

  def get_extension(extensiondata, field_name)
    get_field(extensiondata["extensionField"], field_name)
  end
end
