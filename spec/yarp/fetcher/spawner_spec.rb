require 'spec_helper'
require 'yarp/fetcher/spawner'

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

    subject { Yarp::Fetcher::Spawner.spawn_fetching_thread }

    it 'should take a job from the queue' do
      Yarp::Fetcher::Queue.instance << fetcher
      Yarp::Fetcher::Queue.instance.should_receive(:pop).once
      fetcher.should_receive(:fetch_from_upstream)
      subject.join
    end

    # it 'should run the fetcher relevant method' do
    #   fetcher.should_receive(:fetch_from_upstream)
    #   Yarp::Fetcher::Queue.instance << fetcher
    #   subject.join
    # end

  end


end
