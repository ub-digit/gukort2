class StudentParticipation
  include StudentParsingComponents

  def initialize(data)
    @raw = data
    if !data["LadokParticipation"]
      raise StandardError, "Student message does not contain key: LadokParticipation"
    end

    parse(data["LadokParticipation"])
  end

  def as_json(opt = {})
    {
      person: @person.as_json(opt),
      course: @course
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
      extra: extra
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
      location: location
    }
  end
  
  def parse_extension(extensiondata)
    educode = get_extension(extensiondata, "EducationTypeCode")
    course_title = get_extension(extensiondata, "CoursePackageTitle")

    {
      educode: educode,
      course_title: course_title
    }
  end

  def get_extension(extensiondata, field_name)
    get_field(extensiondata["extensionField"], field_name)
  end
  
  
end
