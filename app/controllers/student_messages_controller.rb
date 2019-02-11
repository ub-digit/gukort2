class StudentMessagesController < ApplicationController
  def create
    student = Student.new(params)
    render json: student
  end
end
