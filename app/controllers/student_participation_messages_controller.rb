class StudentParticipationMessagesController < ApplicationController
  def create
    pp request.raw_post
    data = request.raw_post
    data.force_encoding("UTF-8")
    store_xml(data, "studiedeltagande")
    data = reencode(data, "UTF-8")
    student_participation = StudentParticipation.new(params)

    render json: student_participation
  end
end
