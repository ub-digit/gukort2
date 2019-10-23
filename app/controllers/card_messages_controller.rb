class CardMessagesController < ApplicationController
  def create
  	#log incoming message
  	msg = Message.create(xml: request.raw_post, queue_name: "card")
    card = Card.new(params, msg)
    card.process_card()
    render json: card
  end
end
