class StudentParticipationMessagesController < ApplicationController
  def create
    student_participation = StudentParticipation.new(params)
    render json: student_participation
  end
end
