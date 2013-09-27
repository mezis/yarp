require 'spec_helper'

describe Yarp::Fetcher do
  after :each do
    described_class.paths_being_fetched.values.collect(&:join)
  end

  before :each do
    Yarp::Cache::Memcache.new.send(:_connection).delete('06f74e7966946c1647930a899440755839f74e3e')
  end

  before :each do
    stub_request(:get, "http://eu.yarp.io/abc").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'eu.yarp.io', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "a", :headers => { 'content-type' => '*/*', 'content-length' => '1' })
  end

  describe '.fetch' do
    it 'returns value stored by cache' do
      described_class.cache.stub(:get => 'abc')
      described_class.fetch('/abc').should == 'abc'
    end

    context 'when no matching entry in cache' do
      it 'returns nil' do
        described_class.fetch('/abc').should == nil
      end

      it 'uses apropriate cache key' do
        described_class.cache.should_receive(:get).with('06f74e7966946c1647930a899440755839f74e3e').at_least(:once)
        described_class.fetch('/abc')
      end

      it 'schedules async fetch' do
        described_class.fetch('/abc')
        described_class.paths_being_fetched['/abc'].should be_kind_of(Thread)
      end

      it 'sets cache asynchronously' do
        described_class.fetch('/abc')
        described_class.paths_being_fetched.values.collect(&:join)
        described_class.fetch('/abc').should == [{"content-type"=>["*/*"], "content-length"=>["1"]}, "a"]
      end
    end
  end
end