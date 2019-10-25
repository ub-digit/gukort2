class EmployeeMessagesController < ApplicationController
  def create
  	#log incoming message
  	msg = Message.create(xml: request.raw_post, queue_name: "employee")
    employee = Employee.new(params, msg)
    employee.process_employee()
    render json: employee
  end
end
