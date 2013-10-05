require 'spec_helper'
require 'yarp/fetcher/spawner'
require 'timeout'

describe Yarp::Fetcher::Spawner do

  describe '.spawn_fetching_threads' do

    subject { Yarp::Fetcher::Spawner }

    it 'should spawn a number of threads' do
      n = Yarp::Fetcher::Spawner::FETCHING_THREADS
      subject.should_receive(:spawn_fetching_thread).exactly(n).times
      subject.spawn_fetching_threads
    end
  end

  describe '.spawn_fetching_thread' do

    let(:fetcher) { Yarp::Fetcher.new('/abc') }

    before :each do
      stub_request(:get, "http://eu.yarp.io/abc").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'eu.yarp.io', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "a", :headers => { 'content-type' => '*/*', 'content-length' => '1' })
      Yarp::Fetcher::Queue.instance.clear
    end

    subject do
      Yarp::Fetcher::Spawner.spawn_fetching_thread.tap do |thread|
        thread.abort_on_exception = true
      end
    end

    it 'it processes fetchers as they arrive in queue' do
      subject
      fetcher.should_receive(:fetch_from_upstream)
      Yarp::Fetcher::Queue.instance << fetcher

      # Wait until thread picks up from queue
      Timeout::timeout(1) do
        until Yarp::Fetcher::Queue.instance.length == 0
          # waiting
        end
      end
      subject.kill if subject.alive?
    end

    it 'spawns a thread which gives birth to new thread when dying' do
      # Wait until other threads die
      Timeout::timeout(1) do
        until Thread.list.length == 2 # Main thread + timeout thread
          # waiting
        end
      end
      Yarp::Fetcher::Queue.instance << stub(:path => 'a') # Stub doesn't respond to #fetch_from_upstream
      expect {
        subject.join
      }.to raise_error(RSpec::Mocks::MockExpectationError)
      Thread.list.count.should == 2
    end
  end
end
