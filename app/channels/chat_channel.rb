class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "es_chat"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

	def send_msg(data)
		#byebug
		ActionCable.server.broadcast "es_chat", message: data['message']
	end
end
