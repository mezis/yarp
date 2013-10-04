require 'spec_helper'
require 'yarp/cache/s3'

module Yarp
  module Cache
    describe S3 do

      let(:s3_cache) { Yarp::Cache::S3.new }

      before(:each) do
        ENV['AWS_ACCESS_KEY_ID']     = '123'
        ENV['AWS_SECRET_ACCESS_KEY'] = '123'
        ENV['AWS_BUCKET_NAME']       = 'yarp_test'

        Fog.mock!
        Fog::Mock.reset

        @connection = Fog::Storage.new({
          :provider              => 'AWS',
          :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
          :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
        })
        @directory = @connection.directories.create(
          :key    => ENV['AWS_BUCKET_NAME'],
          :public => true
        )

        Yarp::Cache::S3.any_instance.stub(
          :_connection => @connection,
          :_directory  => @directory
        )
      end

      describe '#fetch' do

        context "when a key is saved" do
          before(:each) do
            @directory.files.create(
              :key    => '123456',
              # NDU2 = '456' in Base64
              :body   => Marshal.dump(['123', 'NDU2'])
            )
          end

          it "should return the key value from its persisted file" do
            value = s3_cache.fetch('123456')
            value.should eql(['123', '456'])
          end

          it "should not save a key if it is already there" do
            s3_cache.fetch('123456') { ['123', 'NDU2'] }
            @directory.should have(1).files
          end

          it "should not overwrite a key if it is already there" do
            value = s3_cache.fetch('123456') { ['321', 'NjU0'] }
            value.should eql(['123', '456'])
          end

        end

        it "should save a key if it isn't saved" do
          s3_cache.fetch('123456') { ['123', '456'] }
          s3_cache.fetch('654321') { ['654', '321'] }
          @directory.should have(2).files
        end

      end

    end
  end
end
