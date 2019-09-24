class StudentMessagesController < ApplicationController
  def create
    pp request.raw_post
    data = request.raw_post
    data.force_encoding("UTF-8")
    store_xml(data, "student")
    data = reencode("UTF-8", data)
    student = Student.new(params)
    render json: student
  end
end
