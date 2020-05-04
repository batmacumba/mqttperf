require 'paho-mqtt'

class Client
	def initialize(clients, mode, length, address, ssl, cert, key, port, topic, elapsed_times, lock, publisher)
		@clients = clients
		@mode = mode
		@length = length
		@address = address
		@ssl = ssl
		@cert = cert
		@key = key
		@port = port
		@topic = topic
		@elapsed_times = elapsed_times
		@lock = lock
		@publisher = publisher
		# Declare callback variables
		@start_time = 0
		@waiting_suback = true
		@waiting_puback = true
		@waiting_message = true

		@client = nil
	end

	def run()
		# Generate message
		o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
		random_string = (0...@length).map { o[rand(o.length)] }.join
		@topic = "/mqttperf/" + Thread.current.object_id.to_s if @topic.nil?
		@client = PahoMqtt::Client.new({host: @address, port: @port, ssl: @ssl})
		register_callbacks()
		@client.ssl ? @client.config_ssl_context(@cert, @key) : nil
		@client.connect(@address)

		# Subscribe to a topic
		if @mode == "r" || @mode == "s"
			@client.subscribe([@topic, 2])
			# Waiting for the suback answer
			while @waiting_suback do
			  sleep 0.001
			end
		end

		# Publish a message and wait for puback
		if @mode == "r" || @mode == "w"
			@start_time = Time.now()
			@client.publish(@topic, random_string, false, 1)

			while @waiting_puback do
			  sleep 0.001
			end
		end
		
		while @waiting_message do
			  sleep 0.001
		end

		@client.disconnect
	end

	def register_callbacks()
		# Register a callback on message event to display messages
		@client.on_message do 
		 	finish()
		end

		# Register a callback on suback to assert the subcription
		@client.on_suback do
			@waiting_suback = false
		end

		# Register a callback for puback event
		@client.on_puback do
			finish() if @mode == "w"
			@waiting_puback = false

		end
	end

	def finish()
		elapsed_time = ((Time.now - @start_time) * 1000).round(3) if @mode == "r" || @mode == "w"
		elapsed_time = Time.now if @mode == "s"
		elapsed_time = @start_time if @publisher
		@lock.synchronize {
			@elapsed_times << elapsed_time 
		} if @lock
		@waiting_message = false
	end

	def waiting_suback()
		return @waiting_suback
	end
end