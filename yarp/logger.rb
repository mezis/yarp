require 'logger'
require 'term/ansicolor'

module Yarp
  class Logger < ::Logger
    SCHEMA = { 'DEBUG' => :uncolored, 'INFO' => :green, 'WARN' => :yellow, 'ERROR' => :red }

    def format_message(level, timestamp, _, message)
      color = SCHEMA[level]
      "[%s] %s\n" % [
        timestamp.strftime('%F %T'),
        Term::ANSIColor.send(color, message)
      ]
    end
  end
end
