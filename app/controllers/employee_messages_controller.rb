class EmployeeMessagesController < ApplicationController
  def create
    employee = Employee.new(params)
    render json: employee
  end
end
