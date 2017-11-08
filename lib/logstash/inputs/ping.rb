# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require 'net/ping'

# This plugin was created as a way to ingest data from ping probes
# into Logstash. You can periodically schedule ingestion
# using a cron syntax (see `schedule` setting).
#
#
# ==== Ping types
#
# This plugin uses 'net/ping' which provides different ways to ping 
# computers. The desired ping mode must be explicitly passed in to the 
# plugin using the `ping_mode` configuration option.
#
# ==== Scheduling
#
# Input from this plugin can be scheduled to run periodically according to a specific
# schedule. This scheduling syntax is powered by https://github.com/jmettraux/rufus-scheduler[rufus-scheduler].
# The syntax is cron-like with some extensions specific to Rufus (e.g. timezone support ).
#
# Examples:
#
# |==========================================================
# | `* 5 * 1-3 *`               | will execute every minute of 5am every day of January through March.
# | `0 * * * *`                 | will execute on the 0th minute of every hour every day.
# | `0 6 * * * America/Chicago` | will execute at 6:00am (UTC/GMT -5) every day.
# |==========================================================
#
#
# Further documentation describing this syntax can be found https://github.com/jmettraux/rufus-scheduler#parsing-cronlines-and-time-strings[here].
#
# ==== Usage:
#
# Here is an example of setting up the plugin to ping google DNS.
# First, we place the appropriate JDBC driver library in our current
# path (this can be placed anywhere on your filesystem). In this example, we connect to
# the 'mydb' database using the user: 'mysql' and wish to input all rows in the 'songs'
# table that match a specific artist. The following examples demonstrates a possible
# Logstash configuration for this. The `schedule` option in this example will
# instruct the plugin to execute this input statement on the minute, every minute.
#
# [source,ruby]
# ------------------------------------------------------------------------------
# input {
#   ping {
#     mode => "external"
#     host => "8.8.8.8"
#     timeout => 5
#     schedule => "* * * * * *"
#   }
# }
# ------------------------------------------------------------------------------
#

class LogStash::Inputs::Ping < LogStash::Inputs::Base
  config_name "ping"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "json"

  # The host to ping.
  #
  # The default, `8.8.8.8`, is the .
  config :host, :validate => :string, :default => "8.8.8.8"

  # The ping mode to use.
  config :mode, :validate => :string, :default => "ICMP"

  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 1

  # Schedule of when to periodically run statement, in Cron format
  # for example: "* * * * * *" (execute ping every second, on the second)
  #
  # There is no schedule by default. If no schedule is given, then the ping is run
  # using `interval` confguration.
  config :schedule, :validate => :string, :default => nil #"* * * * * *"


  public

  def register
    if @schedule
      require "rufus/scheduler"
    end
  end # def register

  def run(queue)
    @action = Rufus::Scheduler.new(:max_work_threads => 1)
    if @schedule
      @scheduler = Rufus::Scheduler.new(:max_work_threads => 1)
      @scheduler.cron @schedule do
        do_ping (queue)
      end

      @scheduler.join
    else
      # we can abort the loop if stop? becomes true
      while !stop?
        do_ping (queue)
        # because the sleep interval can be big, when shutdown happens
        # we want to be able to abort the sleep
        # Stud.stoppable_sleep will frequently evaluate the given block
        # and abort the sleep(@interval) if the return value is true
        Stud.stoppable_sleep(@interval) { stop? }
      end # loop
    end
  end # def run

  def stop
    @scheduler.stop if @scheduler

  end

  private

  def create_probe ()
    @probe = case @mode.upcase
      when "ICMP" then IcmpProbe.new
      when "EXTERNAL" then ExternalProbe.new
      when "HTTP" then HttpProbe.new
      when "TCP" then TcpProbe.new
      when "UDP" then UdpProbe.new
      else
        raise(LogStash::ConfigurationError, "Must set a valid :mode.")
    end

    @probe
  end

  def do_ping (queue)
    success = @probe.ping(@host)
    duration = @probe.duration
    event = LogStash::Event.new("success" => success, "duration" => duration, "host" => @host)
    decorate(event)
    queue << event
  end

  class Probe
    def ping (host)
    end

    def duration ()
    end
  end

  class IcmpProbe < Probe
    def initialize
        @delegate = Net::Ping::ICMP.new
    end

    def ping (host)
        @delegate.ping (host)
    end

    def duration ()
      @delegate.duration
    end
  end

  class ExternalProbe < Probe
    def initialize
        @delegate = Net::Ping::External.new
    end

    def ping (host)
        @delegate.ping (host)
    end

    def duration ()
      @delegate.duration
    end
  end

  class HttpProbe < Probe
  # warning, exception
    def initialize
        @delegate = Net::Ping::HTTP.new
    end

    def ping (host)
        @delegate.ping (host)
    end

    def duration ()
      @delegate.duration
    end
  end

  class TcpProbe < Probe
  # http?
    def initialize
        @delegate = Net::Ping::TCP.new
    end

    def ping (host)
        @delegate.ping (host)
    end

    def duration ()
      @delegate.duration
    end
  end

  class UdpProbe < Probe
  # http?
    def initialize
        @delegate = Net::Ping::UDP.new
    end

    def ping (host)
        @delegate.ping (host)
    end

    def duration ()
      @delegate.duration
    end
  end
end # class LogStash::Inputs::Ping
