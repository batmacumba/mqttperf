require 'paho-mqtt'
require 'descriptive_statistics'
require_relative 'client'

def spread_message(topic)

end

def print_results(n, clients, mode, length, address, ssl, cert, key, port, topic, elapsed_times)
	mode = "Write" if mode == "w"
	mode = "Read" if mode == "r"
	mode = "Spread" if mode == "s"
	print "------------------------------------------------------------\n"
    print "Number of Clients:\t\t#{n}\n"
    print "Benchmark mode:    \t\t#{mode}\n"
    print "#{mode} time min:  \t\t#{elapsed_times.min()} ms\n"
    print "#{mode} time max:  \t\t#{elapsed_times.max()} ms\n"
    print "#{mode} time mean: \t\t#{elapsed_times.mean().round(3)} ms\n"
    print "#{mode} time std:  \t\t#{elapsed_times.standard_deviation().round(3)} ms\n"
    print "------------------------------------------------------------\n"
end

args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
args['clients'].nil? ? n = 1 : n = args['clients'].to_i
args['mode'].nil? ? mode = "w" : mode = args['mode']
args['length'].nil? ? length = 1 : length = args['length'].to_i
args['address'].nil? ? address = '127.0.0.1' : address = args['address']
args['cert'].nil? ? cert = nil : cert = args['cert']
args['key'].nil? ? key = nil : key = args['key']
ssl = !(cert.nil? || key.nil?)
port = args['port']

mode == "s" ? topic = "/mqttperf/spread" : topic = nil

threads = []
clients = []
elapsed_times = []
lock = Mutex.new

n.times {
		clients << Client.new(clients,
							  mode,
							  length,
							  address,
							  ssl,
							  cert,
							  key,
							  port,
							  topic,
							  elapsed_times,
							  lock,
							  false)
}
# Sequential execution
if mode == "r" || mode == "w"
	clients.each do |client|
		client.run()
	end
end
# Parallel execution
if mode == "s"
	# Wait for each client to get its suback
	clients.each do |client|
		threads << Thread.new { client.run() }
		while client.waiting_suback() do
			  sleep 0.001
		end
	end

	start_time = []
	publisher_lock = Mutex.new
	publisher = Client.new(clients,
				    	'w',
				    	length,
				    	address,
				    	ssl,
				    	cert,
				    	key,
				    	port,
				    	topic,
				    	start_time,
				   		publisher_lock,
				   		true)
	publisher.run()
	threads.each(&:join)

	elapsed_times.each_with_index do |t, i|
		elapsed_times[i] = ((t - start_time[0]) * 1000).round(3)
	end

end

print_results(n,
			  clients,
			  mode,
			  length,
			  address,
			  ssl,
			  cert,
			  key,
			  port,
			  topic,
			  elapsed_times)