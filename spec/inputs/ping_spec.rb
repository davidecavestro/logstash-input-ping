# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/ping"
require "net/ping"
require "timecop"
require "time"
require "date"

describe LogStash::Inputs::Ping do

  let(:plugin) { LogStash::Inputs::Ping.new(config) }
  let(:queue) { Queue.new }

  it_behaves_like "an interruptible input plugin" do
    let(:config) do
      {
        "host" => ["127.0.0.1"],
        "mode" => "external",
        "schedule" => "* * * * * UTC"
      }
    end
  end

  context "when scheduling" do
    let(:config) do
      {
          "host" => ["127.0.0.1"],
          "mode" => "external",
          "schedule" => "* * * * * UTC"
      }
    end

    before do
      plugin.register
    end

    it "should properly schedule" do

      Timecop.travel(Time.new(2000))
      Timecop.scale(60)
      runner = Thread.new do
        expect(plugin).to receive(:do_ping) {
          queue << LogStash::Event.new({})
        }.at_least(:twice)

        plugin.run(queue)
      end
      sleep 3
      plugin.stop
      runner.kill
      runner.join
      expect(queue.size).to eq(2)
      Timecop.return
    end

  end

end
