class HomeController < ApplicationController
	include ActionController::Live

	def ticker
		5.times do
			response.stream.write "Olá!: #{Time.now} <br>"
			sleep 2
		end
		response.stream.close
	end

	def live
		response.headers['Content-Type'] = 'text/event-stream'
		sse = SSE.new(response.stream, retry: 300, event: "event-name")
		loop do
			sse.write({time: Time.now}, id: 10, event: "other-event", retry: 500)
			sleep 2
		end
		rescue ClientDisconnected
			logger.info 'Client disconnects causes IOError on write'
		ensure
		sse.close
	end

	def sse
	end

	def chat
	end

end
