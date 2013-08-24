require 'newrelic_rpm'

if defined? Unicorn
  NewRelic::Agent.after_fork(:force_reconnect => true)
end
