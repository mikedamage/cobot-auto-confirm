# Cobot Membership Auto-Confirm

by Mike Green (mike AT fifthroomcreative DOT com)
Copyright (C) 2010 Converge Coworking, LLC

## Summary

This script will connect to the Cobot OAuth API on behalf of a user (with admin privileges) and run through the list of members, automatically confirming any unconfirmed members. It requires you to obtain an OAuth Access Token and Access Secret from Cobot, which I'll cover in the _Authorizing This Script_ section below.

I wrote this script for [Converge Coworking](http://www.convergenj.com), an awesome coworking space located in Union, NJ on the campus of Kean University (shameless plug). We needed a way to automatically confirm new coworkers who sign up for accounts so they can check-in immediately. If you use Cobot to manage your coworking space, I hope you find this script useful. If you don't use Cobot, you really should! It handles signup, billing, memberships and addons, as well as perks like conference room booking. It's a one stop shop for coworking space administration. That was another shameless plug, by the way, but I am not affiliated with Cobot in any way.

## Usage

The output of the `--help` flag pretty much says it all:

	Cobot Membership Auto-Confirm Script
	Usage: auto-confirm.rb [options]

	Options:
			-c, --config=CONF_FILE           Get OAuth configuration from specified YAML file. CLI flags take precedence.
			-t, --consumer-token=TOKEN       OAuth Consumer Token
			-s, --consumer-secret=SECRET     OAuth Consumer Secret
			-T, --access-token=TOKEN         OAuth Access Token
			-S, --access-secret=SECRET       OAuth Access Secret
			-d, --cobot-subdomain=SUBDOMAIN  Cobot subdomain (i.e. "convergenj")
			-h, --help                       Display usage information
	

## Authorizing This Script

OAuth is an elegant little dance, in which an application and web service exchange sets of keys. The grand purpose of the dance is for the web service to grant an application access to your data without the application needing to know your username and password. In the case of interactive web apps, it's completely automated; but ironically enough, since our script is completely automated you'll need to do some of the steps manually. __You only need to do this once. Once you've gotten your Access Token and Access Secret, they can be used indefinitely.__

Here's a quick and dirty tutorial on obtaining the OAuth keys this script requires:

### What you need:
1. A Cobot account with admin privileges
2. Ruby & RubyGems w/ the OAuth and JSON gems installed
3. The example PHP callback script, uploaded to your website. (TODO: add PHP callback script to repo)

First you need to register the script with Cobot to get your Consumer Key and Consumer Secret. Login to your cobot account, then visit https://www.cobot.me/oauth_clients/new. Fill in all the required fields - the callback URL is the URL of the PHP callback script. _Note: you don't actually need to use my callback script for this, but you do need to enter something for the callback URL._

Once the script is registered with Cobot as an application, copy down the Consumer Key and Consumer Secret that appear on the next page. You don't need to worry about the URLs as long as you're using the Ruby OAuth gem. They're standard OAuth URLs that the gem can guess on its own.

Now that you've got your Consumer Key and Secret, fire up IRB and run some code:
	> require 'rubygems'
	> require 'oauth'
	> consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, {:site => 'https://www.cobot.me'})
	> request_token = consumer.get_request_token
	=> "https://www.cobot.me/oauth/authorize?oauth_token=<request_token>"

Leave IRB open and paste the Authorize URL into your web browser. Check the checkbox that appears and submit the form. You'll be redirected to the Callback URL that you registered earlier, and some OAuth tokens will be appended to the query string. The callback script I've included will display these query string variables in your browser as well. You're interested in the value of the OAuth Verifier parameter. Copy this to your clipboard for use in the next step.

Back in IRB, run the following code:
	> access_token = consumer.get_access_token(request_token, {:oauth_verifier => OAUTH_VERIFIER})
	> access_token.token
	=> "ACCESS_TOKEN"
	> access_token.secret
	=> "ACCESS_SECRET"

Test your Access Token by making a request to the Cobot API:
	> user = access_token.get('/api/user')
	=> #<Net::HTTPOK 200 OK readbody=true>
As long as it returns a class of `Net::HTTPOK`, you're golden.

You've just exchanged your Request Token and Secret for an Access Token and Access Secret. Copy these values and save them somewhere. You now have everything you need to run the auto confirm script.

## License
This script is released under the terms of the GNU General Public License v3.0. See [LICENSE](https://github.com/mikedamage/cobot-auto-confirm/blob/master/LICENSE) for more details.
