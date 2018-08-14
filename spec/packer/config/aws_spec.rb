require 'packer/config'
require 'timecop'

describe Packer::Config::Aws do
  describe 'builders' do
    before :each do
      Timecop.freeze
    end

    after :each do
      Timecop.return
    end

    it 'returns the expected builders' do
      regions = [
        {
          'name' => 'region1',
          'base_ami' => 'baseami1',
          'vpc_id' => 'vpc1',
          'subnet_id' => 'subnet1',
          'security_group' => 'sg1'
        }
      ]
      builders = Packer::Config::Aws.new(
        aws_access_key: 'some-aws-access-key',
        aws_secret_key: 'some-aws-secret-key',
        regions: regions,
        output_directory: '',
        os: '',
        vm_prefix: 'some-vm-prefix'
      ).builders
      expect(builders[0]).to include(
        'name' => 'amazon-ebs-region1',
        'type' => 'amazon-ebs',
        'access_key' => 'some-aws-access-key',
        'secret_key' => 'some-aws-secret-key',
        'region' => 'region1',
        'source_ami' => 'baseami1',
        'instance_type' => 'm4.xlarge',
        'vpc_id' => 'vpc1',
        'subnet_id' => 'subnet1',
        'associate_public_ip_address' => true,
        'communicator' => 'winrm',
        'winrm_username' => 'Administrator',
        'winrm_timeout' => '1h',
        'user_data_file' => 'scripts/aws/setup_winrm.txt',
        'security_group_id' => 'sg1',
        'ami_groups' => 'all',
        'run_tags' => {'Name' => "some-vm-prefix-#{Time.now.to_i}"}
      )
      expect(builders[0]['ami_name']).to match(/BOSH-.*-region1/)
    end

    it 'returns the expected builders using an m5.large for windows2016' do
      regions = [
        {
          'name' => 'region1',
          'base_ami' => 'baseami1',
          'vpc_id' => 'vpc1',
          'subnet_id' => 'subnet1',
          'security_group' => 'sg1'
        }
      ]
      builders = Packer::Config::Aws.new(
        aws_access_key: 'some-aws-access-key',
        aws_secret_key: 'some-aws-secret-key',
        regions: regions,
        output_directory: 'some-output-directory',
        os: 'windows2016',
        vm_prefix: 'some-vm-prefix'
      ).builders
      expect(builders[0]).to include(
        'name' => 'amazon-ebs-region1',
        'type' => 'amazon-ebs',
        'access_key' => 'some-aws-access-key',
        'secret_key' => 'some-aws-secret-key',
        'region' => 'region1',
        'source_ami' => 'baseami1',
        'instance_type' => 'm5.large',
        'vpc_id' => 'vpc1',
        'subnet_id' => 'subnet1',
        'associate_public_ip_address' => true,
        'communicator' => 'winrm',
        'winrm_username' => 'Administrator',
        'winrm_timeout' => '1h',
        'user_data_file' => 'scripts/aws/setup_winrm.txt',
        'security_group_id' => 'sg1',
        'ami_groups' => 'all',
        'run_tags' => {'Name' => "some-vm-prefix-#{Time.now.to_i}"}
      )
      expect(builders[0]['ami_name']).to match(/BOSH-.*-region1/)
    end

    it 'returns the expected builders using an m5.large for windows1803' do
      regions = [
        {
          'name' => 'region1',
          'base_ami' => 'baseami1',
          'vpc_id' => 'vpc1',
          'subnet_id' => 'subnet1',
          'security_group' => 'sg1'
        }
      ]
      builders = Packer::Config::Aws.new(
        aws_access_key: 'some-aws-access-key',
        aws_secret_key: 'some-aws-secret-key',
        regions: regions,
        output_directory: 'some-output-directory',
        os: 'windows1803',
        vm_prefix: 'some-vm-prefix'
      ).builders
      expect(builders[0]).to include(
                               'name' => 'amazon-ebs-region1',
                               'type' => 'amazon-ebs',
                               'access_key' => 'some-aws-access-key',
                               'secret_key' => 'some-aws-secret-key',
                               'region' => 'region1',
                               'source_ami' => 'baseami1',
                               'instance_type' => 'm5.large',
                               'vpc_id' => 'vpc1',
                               'subnet_id' => 'subnet1',
                               'associate_public_ip_address' => true,
                               'communicator' => 'winrm',
                               'winrm_username' => 'Administrator',
                               'winrm_timeout' => '1h',
                               'user_data_file' => 'scripts/aws/setup_winrm.txt',
                               'security_group_id' => 'sg1',
                               'ami_groups' => 'all',
                               'run_tags' => {'Name' => "some-vm-prefix-#{Time.now.to_i}"}
                             )
      expect(builders[0]['ami_name']).to match(/BOSH-.*-region1/)
    end

    context 'when vm_prefix is empty' do
      it 'defaults to packer' do
        builders = Packer::Config::Aws.new(
          aws_access_key: '',
          aws_secret_key: '',
          regions: [{}],
          output_directory: '',
          os: '',
          vm_prefix: ''
        ).builders
        expect(builders[0]).to include(
          'run_tags' => {'Name' => "packer-#{Time.now.to_i}"}
        )
      end
    end
  end

  describe 'provisioners' do
    before(:each) do
      @stemcell_deps_dir = Dir.mktmpdir('gcp')
      ENV['STEMCELL_DEPS_DIR'] = @stemcell_deps_dir
    end

    after(:each) do
      FileUtils.rm_rf(@stemcell_deps_dir)
      ENV.delete('STEMCELL_DEPS_DIR')
    end

    context 'windows 2012' do
      it 'returns the expected provisioners' do
        allow(SecureRandom).to receive(:hex).and_return("some-password")
        provisioners = Packer::Config::Aws.new(
            aws_access_key: '',
            aws_secret_key: '',
            regions: [],
            output_directory: 'some-output-directory',
            os: 'windows2012R2',
            vm_prefix: '',
            mount_ephemeral_disk: false,
        ).provisioners
        expected_provisioners_except_lgpo = [
          {"type"=>"file", "source"=>"build/bosh-psmodules.zip", "destination"=>"C:\\provision\\bosh-psmodules.zip"},
          {"type"=>"powershell", "scripts"=>["scripts/install-bosh-psmodules.ps1"]},
          {'type'=>'powershell', 'inline'=>['$ErrorActionPreference = "Stop";',
                                            'trap { $host.SetShouldExit(1) }',
                                            'Set-ProxySettings   ']},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "New-Provisioner"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Install-CFFeatures"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Add-Account -User Provisioner -Password some-password!"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Register-WindowsUpdatesTask"]},
          {"type"=>"windows-restart", "restart_command"=>"powershell.exe -Command Wait-WindowsUpdates -Password some-password! -User Provisioner", "restart_timeout"=>"12h"},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Unregister-WindowsUpdatesTask"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Remove-Account -User Provisioner"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Test-InstalledUpdates"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Protect-CFCell"]},
          {"type"=>"file", "source"=>"../sshd/OpenSSH-Win64.zip", "destination"=>"C:\\provision\\OpenSSH-Win64.zip"},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Install-SSHD -SSHZipFile 'C:\\provision\\OpenSSH-Win64.zip'"]},
          {"type"=>"file", "source"=>"build/agent.zip", "destination"=>"C:\\provision\\agent.zip"},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Install-Agent -IaaS aws -agentZipPath 'C:\\provision\\agent.zip'"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Get-Hotfix | Out-File -FilePath \"C:\\updates.txt\" -Encoding ASCII"]},
          {"type"=>"file", "source"=>"C:\\updates.txt", "destination"=>"some-output-directory/updates.txt", "direction"=>"download"},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Enable-CVE-2015-6161"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Enable-CVE-2017-8529"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Enable-CredSSP"]},
          {'type'=>'powershell', 'inline'=> ['$ErrorActionPreference = "Stop";',
                                             'trap { $host.SetShouldExit(1) }',
                                             'Clear-ProxySettings']},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Clear-Provisioner"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Invoke-Sysprep -IaaS aws -OsVersion windows2012R2"]}
        ].flatten
        expect(provisioners.detect {|x| x['destination'] == "C:\\windows\\LGPO.exe"}).not_to be_nil
        provisioners_no_lgpo = provisioners.delete_if {|x| x['destination'] == "C:\\windows\\LGPO.exe"}
        expect(provisioners_no_lgpo).to eq (expected_provisioners_except_lgpo)
      end
    end

    context 'windows 2016' do
      it 'returns the expected provisioners' do
        stemcell_deps_dir = Dir.mktmpdir('aws')
        ENV['STEMCELL_DEPS_DIR'] = stemcell_deps_dir

        allow(SecureRandom).to receive(:hex).and_return("some-password")
        provisioners = Packer::Config::Aws.new(
          aws_access_key: '',
          aws_secret_key: '',
          regions: [],
          output_directory: 'some-output-directory',
          os: 'windows2016',
          vm_prefix: '',
        ).provisioners
        expected_provisioners_except_lgpo = [
          {"type"=>"file", "source"=>"build/bosh-psmodules.zip", "destination"=>"C:\\provision\\bosh-psmodules.zip"},
          {"type"=>"powershell", "scripts"=>["scripts/install-bosh-psmodules.ps1"]},
          {'type'=>'powershell', 'inline'=>['$ErrorActionPreference = "Stop";',
                                            'trap { $host.SetShouldExit(1) }',
                                            'Set-ProxySettings   ']},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "New-Provisioner"]},
          {"type"=>"windows-restart", "restart_command"=>"powershell.exe -Command Install-CFFeatures", "restart_timeout"=>"1h"},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Add-Account -User Provisioner -Password some-password!"]},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Register-WindowsUpdatesTask"]},
          {"type"=>"windows-restart", "restart_command"=> "powershell.exe -Command Wait-WindowsUpdates -Password some-password! -User Provisioner", "restart_timeout"=>"12h"},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Unregister-WindowsUpdatesTask"]},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Remove-Account -User Provisioner"]},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Protect-CFCell"]},
          {"type"=>"file", "source"=>"../sshd/OpenSSH-Win64.zip", "destination"=>"C:\\provision\\OpenSSH-Win64.zip"},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Install-SSHD -SSHZipFile 'C:\\provision\\OpenSSH-Win64.zip'"]},
          {"type"=>"file", "source"=>"build/agent.zip", "destination"=>"C:\\provision\\agent.zip"},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Install-Agent -IaaS aws -agentZipPath 'C:\\provision\\agent.zip'"]},
          {"type"=>"powershell", "inline"=>["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Get-Hotfix | Out-File -FilePath \"C:\\updates.txt\" -Encoding ASCII"]},
          {"type"=>"file", "source"=>"C:\\updates.txt", "destination"=>"some-output-directory/updates.txt", "direction"=>"download"},
          {'type'=>'powershell', 'inline'=> ['$ErrorActionPreference = "Stop";',
                                             'trap { $host.SetShouldExit(1) }',
                                             'Clear-ProxySettings']},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Clear-Provisioner"]},
          {"type"=>"powershell", "inline"=> ["$ErrorActionPreference = \"Stop\";", "trap { $host.SetShouldExit(1) }", "Invoke-Sysprep -IaaS aws -OsVersion windows2016"]}
        ].flatten
        expect(provisioners.detect {|x| x['destination'] == "C:\\windows\\LGPO.exe"}).not_to be_nil
        provisioners_no_lgpo = provisioners.delete_if {|x| x['destination'] == "C:\\windows\\LGPO.exe"}
        expect(provisioners_no_lgpo).to eq (expected_provisioners_except_lgpo)

        FileUtils.rm_rf(stemcell_deps_dir)
        ENV.delete('STEMCELL_DEPS_DIR')
      end

      context 'when provisioning with emphemeral disk mounting enabled' do
        it 'calls Install-Agent with -EnableEphemeralDiskMounting' do
          allow(SecureRandom).to receive(:hex).and_return("some-password")
          provisioners = Packer::Config::Aws.new(
            aws_access_key: '',
            aws_secret_key: '',
            regions: [],
            output_directory: 'some-output-directory',
            os: 'windows2016',
            vm_prefix: '',
            mount_ephemeral_disk: true,
          ).provisioners

          expect(provisioners).to include(
            {
              "type"=>"powershell",
              "inline"=>[
                "$ErrorActionPreference = \"Stop\";",
                "trap { $host.SetShouldExit(1) }",
                "Install-Agent -IaaS aws -agentZipPath 'C:\\provision\\agent.zip' -EnableEphemeralDiskMounting"
              ]
            }
          )
        end
      end
    end
  end
end
