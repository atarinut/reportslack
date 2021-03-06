require 'puppet'
require 'yaml'
require 'slack-notifier'

Puppet::Reports.register_report(:slack) do
	if (Puppet.settings[:config]) then
		configfile = File.join([File.dirname(Puppet.settings[:config]), "slack.yaml"])
	else
		configfile = "/etc/puppetlabs/puppet/slack.yaml"
	end
  Puppet.debug "Reading #{configfile}"
	raise(Puppet::ParseError, "Slack report config file #{configfile} not readable") unless File.exist?(configfile)
	config = YAML.load_file(configfile)
	SLACK_WEBHOOK_URL = config['webhook_url']
  Puppet.debug "Webhook is #{SLACK_WEBHOOK_URL}"
	SLACK_CHANNEL = config['channel']
	DISABLED_FILE = File.join([File.dirname(Puppet.settings[:config]), 'slack_disabled'])

	def process
		disabled = File.exists?(DISABLED_FILE)

		if (!disabled && self.status != 'unchanged')
			Puppet.debug "Sending notification for #{self.host} to Slack channel #{SLACK_CHANNEL}"
			msg = "Puppet run for #{self.host} #{self.status} at #{Time.now.asctime} on #{self.configuration_version} in #{self.environment}. Report available <https://#{Puppet.settings[:ca_server]}/#/node_groups/inventory/node/#{self.host}/reports|here>"
			notifier = Slack::Notifier.new SLACK_WEBHOOK_URL, channel: SLACK_CHANNEL, username: 'Puppet'
			notifier.ping msg, icon_url: "https://puppetlabs.com/wp-content/uploads/2010/12/PL_logo_vertical_RGB_lg.jpg"
		end
	end
end
