require 'fileutils'
require 'json'
require 'rake'
require 'rubygems/package'
require 'tmpdir'
require 'yaml'
require 'zlib'
require 's3'

load File.expand_path('../../../../lib/tasks/build/aws.rake', __FILE__)

describe 'Aws' do
  before(:each) do
    @original_env = ENV.to_hash
    @build_dir = File.expand_path('../../../../build', __FILE__)
    @version_dir = Dir.mktmpdir('aws')
    @agent_dir = Dir.mktmpdir('aws')
    @base_amis_dir = Dir.mktmpdir('aws')
    @output_directory = 'bosh-windows-stemcell'
    FileUtils.rm_rf(@output_directory)
    Rake::Task['build:aws'].reenable
  end

  after(:each) do
    ENV.replace(@original_env)
    FileUtils.rm_rf(@output_directory)
    FileUtils.rm_rf(@version_dir)
    FileUtils.rm_rf(@agent_dir)
    FileUtils.rm_rf(@base_amis_dir)
  end

  it 'should build an aws stemcell' do
    Dir.mktmpdir('aws-stemcell-test') do |tmpdir|
      os_version = 'windows2012R2'
      version = '1200.3.1-build.2'
      agent_commit = 'some-agent-commit'

      ENV['AWS_ACCESS_KEY'] = aws_access_key = 'some-aws_access_key'
      ENV['AWS_SECRET_KEY'] = aws_secret_key = 'some-aws_secret_key'
      ENV['OS_VERSION'] = os_version
      ENV['PATH'] = "#{File.join(File.expand_path('../../../..', __FILE__), 'spec', 'fixtures', 'aws')}:#{ENV['PATH']}"
      ENV['VERSION_DIR'] = @version_dir
      ENV['BASE_AMIS_DIR'] = @base_amis_dir
      ENV['REGION'] = region = 'us-east-1'
      ENV['OUTPUT_BUCKET_REGION'] = output_bucket_region = 'some-output-bucket-region'
      ENV['OUTPUT_BUCKET_NAME'] = output_bucket_name = 'some-output-bucket-name'

      File.write(
        File.join(@version_dir, 'number'),
        version
      )

      FileUtils.mkdir_p(File.join(@build_dir, 'compiled-agent'))
      File.write(
        File.join(@build_dir, 'compiled-agent', 'sha'),
        agent_commit
      )

      File.write(
        File.join(@base_amis_dir, 'base-amis-1.json'),
        [
            {
              "name" => "us-east-1",
              "base_ami" => "base-east-1"
            },
            {
              "name" => "us-east-2",
              "base_ami" => "base-east-2"
            }
        ].to_json
      )

      s3_client = double(:s3_client)
      allow(s3_client).to receive(:put)
      allow(S3::Client).to receive(:new).with(
        aws_access_key_id: aws_access_key,
        aws_secret_access_key: aws_secret_key,
        aws_region: output_bucket_region
      ).and_return(s3_client)

      Rake::Task['build:aws'].invoke

      stemcell = File.join(@output_directory, "light-bosh-stemcell-#{version}-aws-xen-hvm-#{os_version}-go_agent-#{region}.tgz")
      stemcell_sha = File.join(@output_directory, "light-bosh-stemcell-#{version}-aws-xen-hvm-#{os_version}-go_agent-#{region}.tgz.sha")

      stemcell_manifest = YAML.load(read_from_tgz(stemcell, 'stemcell.MF'))
      expect(stemcell_manifest['version']).to eq('1200.3')
      expect(stemcell_manifest['sha1']).to eq(EMPTY_FILE_SHA)
      expect(stemcell_manifest['operating_system']).to eq(os_version)
      expect(stemcell_manifest['cloud_properties']['infrastructure']).to eq('aws')
      expect(stemcell_manifest['cloud_properties']['ami']['us-east-1']).to eq('ami-east1id')
      expect(stemcell_manifest['cloud_properties']['ami']['us-east-2']).to be_nil

      apply_spec = JSON.parse(read_from_tgz(stemcell, 'apply_spec.yml'))
      expect(apply_spec['agent_commit']).to eq(agent_commit)

      expect(read_from_tgz(stemcell, 'updates.txt')).to eq('some-updates')

      expect(read_from_tgz(stemcell, 'image')).to be_nil
      expect(File.read(stemcell_sha)).to eq(Digest::SHA1.hexdigest(File.read(stemcell)))
    end
  end
end
