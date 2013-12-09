require 'spec_helper'
require 'yarp/fetcher'

describe Yarp::Fetcher do
  subject { described_class.new('/abc').perform }

  describe '.perform' do
    it 'returns value stored by cache' do
      Yarp::ConcreteCache.instance.stub(:get).and_return('abc')
      subject.should == 'abc'
    end

    context 'when no matching entry in cache' do
      it 'returns nil' do
        subject.should == nil
      end

      it 'uses apropriate cache key' do
        Yarp::ConcreteCache.instance.should_receive(:get).with('06f74e7966946c1647930a899440755839f74e3e').at_least(:once)
        subject
      end

      it 'schedules async fetch' do
        Yarp::Fetcher::Queue.instance.should_receive(:<<)
        subject
      end
    end
  end

  describe '#fetch_from_upstrean' do

    before :each do
      stub_request(:get, "http://yarp.example.com/abc").
        to_return(:status => 200, :body => "a", :headers => { 'content-type' => '*/*', 'content-length' => '1' })
    end

    it 'fetches from upstream and sets cache' do
      Yarp::ConcreteCache.instance.should_receive(:fetch) do |cache_key, ttl, &block|
        cache_key.should == '06f74e7966946c1647930a899440755839f74e3e'
        block.call.should == [{"content-type"=>["*/*"], "content-length"=>["1"]}, "a"]
      end.and_return('abc')
      described_class.new('/abc').fetch_from_upstream
    end
  end
end
