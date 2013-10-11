require 'spec_helper'
require 'yarp/fetcher/queue'
require 'yarp/fetcher'

describe Yarp::Fetcher::Queue do
  subject { described_class.instance }

  let(:fetcher) { Yarp::Fetcher.new('fetcher') }

  before :each do
    subject.clear
  end


  describe '.new' do
    it 'raises an exception' do
      expect {
        described_class.new
      }.to raise_error
    end
  end

  describe 'instance' do
    it 'returns same instance every time' do
      subject.object_id.should == described_class.instance.object_id
    end
  end

  describe '#<<' do
    it 'puts object to queue' do
      subject << fetcher
      subject.length.should == 1
    end

    it 'does not allow to put two object to queue twice' do
      subject << fetcher
      subject << fetcher
      subject.length.should == 1
    end
  end

  describe '#done' do
    it 'allows to put object with same path again' do
      subject << fetcher
      subject.done(fetcher)
      subject << fetcher
      subject.length.should == 2
    end

  end

  describe '#pop' do
    it 'pops element from queue' do
      subject << fetcher
      subject << Yarp::Fetcher.new('other fetcher')
      subject.pop.should == fetcher
    end
  end
end