class StudentMessagesController < ApplicationController
  def create
  	#log incoming message
    # Bypass ActionPack XML Parser, and remove xml encoding before use. It will always be UTF-8
    input_xml = request.raw_post.gsub(/<?xml version=(.*) encoding=.*?>/, '<?xml version=\1?>')
    params = Hash.from_xml(input_xml)
    msg = Message.create(xml: input_xml, queue_name: "student")
    student = Student.new(params, msg)
    student.process_student()
    render json: student
  end
end
