class StudentMessagesController < ApplicationController
  def create
  	#log incoming message
  	msg = Message.create(xml: request.raw_post, queue_name: "student")
    student = Student.new(params, msg)
    student.process_student()
    render json: student
  end
end
