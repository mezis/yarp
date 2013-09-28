require 'spec_helper'

describe Yarp::Fetcher do

  describe '.fetch' do
    subject { described_class.fetch('/abc') }

    after :each do
      described_class.paths_being_fetched.values.collect(&:join)
    end

    before :each do
      Yarp::Cache::Memcache.new.send(:_connection).delete('06f74e7966946c1647930a899440755839f74e3e')
      stub_request(:get, "http://eu.yarp.io/abc").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'eu.yarp.io', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "a", :headers => { 'content-type' => '*/*', 'content-length' => '1' })
    end

    it 'returns value stored by cache' do
      described_class.cache.stub(:get => 'abc')
      subject.should == 'abc'
    end

    context 'when no matching entry in cache' do
      it 'returns nil' do
        subject.should == nil
      end

      it 'uses apropriate cache key' do
        described_class.cache.should_receive(:get).with('06f74e7966946c1647930a899440755839f74e3e').at_least(:once)
        subject
      end

      it 'schedules one async fetch per path' do
        expect {
          described_class.fetch('/abc')
          described_class.fetch('/abc')
        }.to change {
          described_class.paths_being_fetched.count
        }.by(1)
      end

      it 'sets cache asynchronously' do
        described_class.fetch('/abc')
        described_class.paths_being_fetched.values.collect(&:join)
        described_class.fetch('/abc').should == [{"content-type"=>["*/*"], "content-length"=>["1"]}, "a"]
      end
    end
  end
end