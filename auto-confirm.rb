#!/usr/bin/env ruby
#
# = Converge Coworking: Membership Auto-Confirm Script
# 
# AUTHOR:: Mike Green <mike@fifthroomcreative.com>
# DESCRIPTION:: Fetches a list of coworking space members from the Cobot.me API and auto-confirms any unconfirmed new members.
# LICENSE:: GNU General Public License 

require 'ostruct'
require 'optparse'
require 'yaml'
require 'rubygems'
require 'oauth'
require 'json'

class Application
	
	def initialize(args)
		@arguments = args
		@config    = OpenStruct.new
	end

	def run!
		if args_parsed?
			if config_valid?
				# Use access_token to execute requests against the Cobot API
				# 	@access_token.get('/api/memberships') => #<Net::HTTPOK 200 OK readbody=true>
				# Use the #body method of the response object to get at the gooey JSON center of each request.

				@consumer     = OAuth::Consumer.new(@config.consumer_token, @config.consumer_secret, {:site => "https://#{@config.cobot_subdomain}.cobot.me"})
				@access_token = OAuth::AccessToken.new(@consumer, @config.access_token, @config.access_secret)
				@memberships  = JSON.parse(@access_token.get('/api/memberships').body)
				@unconfirmed  = @memberships.select {|member| member['confirmed_at'].nil? }
				
				if @unconfirmed.any?
					mark_members_confirmed
				else
					puts "No unconfirmed members found. Exiting..."
					exit 0
				end
			else
				raise "Invalid Configuration!\nOAuth keys must be specified in a config file or via the CLI flags. Run `#{File.basename(__FILE__)} -h` for help."
			end
			raise 'Error parsing command line arguments!'
		end
	end
	
	private
		def mark_members_confirmed
			results = []
			@unconfirmed.each do |member|
				puts "Confirming #{member['address']['name']} (username: #{member['user']['login']})"
				result = @access_token.post("/api/memberships/#{member['id']}/confirmation")
				results << result	

				if result.is_a? Net::HTTPCreated
					puts "Success"
				else
					puts "Error"
				end
			end

			if results.all? {|result| result.is_a? Net::HTTPCreated }
				puts "All members successfully confirmed!"
				exit 0
			else
				failures = results.reject {|result| result.is_a? Net::HTTPCreated }
				puts "Encountered errors while trying to confirm #{failures.nitems} members"
				exit 2
			end
		end

		def args_parsed?
			opts = OptionParser.new
			opts.banner = <<END_BANNER
Cobot Membership Auto-Confirm Script
Usage: #{File.basename(__FILE__)} [options]

Options:
END_BANNER
			opts.on('-c', '--config=CONF_FILE', 'Get OAuth configuration from specified YAML file. CLI flags take precedence.') {|conf_file| @config.conf_file = conf_file }
			opts.on('-t', '--consumer-token=TOKEN', 'OAuth Consumer Token') {|token| @config.consumer_token = token }
			opts.on('-s', '--consumer-secret=SECRET', 'OAuth Consumer Secret') {|secret| @config.consumer_secret = secret }
			opts.on('-T', '--access-token=TOKEN', 'OAuth Access Token') {|token| @config.access_token = token }
			opts.on('-S', '--access-secret=SECRET', 'OAuth Access Secret') {|secret| @config.access_secret = secret }
			opts.on('-d', '--cobot-subdomain=SUBDOMAIN', 'Cobot subdomain (i.e. "convergenj")') {|subdomain| @config.cobot_subdomain = subdomain }
			opts.on('-h', '--help', 'Display usage information') { puts opts; exit 0 }
			return true if opts.parse!(@arguments)
			false
		end

		def config_valid?
			if @config.conf_file && FileTest.exist?(@config.conf_file)
				@yaml_config = YAML.load_file(@config.conf_file)
				@config.cobot_subdomain ||= @yaml_config['cobot_subdomain']
				@config.consumer_token  ||= @yaml_config['consumer']['token']
				@config.consumer_secret ||= @yaml_config['consumer']['secret']
				@config.access_token    ||= @yaml_config['access']['token']
				@config.access_secret   ||= @yaml_config['access']['secret']
			end

			return true if @config.cobot_subdomain && @config.consumer_token && @config.consumer_secret && @config.access_token && @config.access_secret
			false
		end
end

app = Application.new(ARGV)

begin
	app.run!
rescue => e
	puts "Error: #{e}"
	exit 1
end
