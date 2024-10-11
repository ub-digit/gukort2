class EmployeePopMessagesController < ApplicationController
  def create
      #log incoming message
    # Bypass ActionPack XML Parser, and remove xml encoding before use. It will always be UTF-8
    input_json = request.raw_post
    params = JSON.parse(input_json)
    msg = Message.create(xml: input_json, queue_name: "employee_pop")
    user = EmployeePop.new(params, msg)
    user.process_employee()
    render json: user
  end
end
