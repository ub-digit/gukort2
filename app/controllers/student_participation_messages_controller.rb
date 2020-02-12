class StudentParticipationMessagesController < ApplicationController
  def create
  	#log incoming message
    # Bypass ActionPack XML Parser, and remove xml encoding before use. It will always be UTF-8
    input_xml = request.raw_post.gsub(/<?xml version=(.*) encoding=.*?>/, '<?xml version=\1?>')
    params = Hash.from_xml(input_xml)
    msg = Message.create(xml: input_xml, queue_name: "student_participation")
    student_participation = StudentParticipation.new(params, msg)
    student_participation.process_student_participation()
    render json: student_participation
  end
end
