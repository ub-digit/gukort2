class StudentParticipation
  include StudentParsingComponents

  def initialize(data, msg)
    @raw = data
    @msg = msg
    if !data["LadokParticipation"]
      raise StandardError, "Student message does not contain key: LadokParticipation"
    end

    parse(data["LadokParticipation"])
  end

  def process_student_participation
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
