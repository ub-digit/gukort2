class StudentParticipationMessagesController < ApplicationController
  def create
  	#log incoming message
  	msg = Message.create(xml: request.raw_post, queue_name: "student_participation")
    student_participation = StudentParticipation.new(params, msg)
    student_participation.process_student_participation()
    render json: student_participation
  end
end
