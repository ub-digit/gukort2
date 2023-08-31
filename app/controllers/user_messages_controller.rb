class UserMessagesController < ApplicationController
  def create
  	#log incoming message
    # Bypass ActionPack XML Parser, and remove xml encoding before use. It will always be UTF-8
    input_json = request.raw_post
    params = JSON.parse(input_json)
    msg = Message.create(xml: input_json, queue_name: "user")
    user = User.new(params, msg)
    user.process_user()
    render json: user
  end
end
