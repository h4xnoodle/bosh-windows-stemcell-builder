require 'securerandom'

module Packer
  module Config
    class VSphereBase < Base
      def initialize(administrator_password:,
                     source_path:,
                     mem_size:,
                     num_vcpus:,
                     skip_windows_update:false,
                     http_proxy:,
                     https_proxy:,
                     bypass_list:,
                    **args)
        @administrator_password = administrator_password
        @source_path = source_path
        @mem_size = mem_size
        @num_vcpus = num_vcpus
        @timestamp = Time.now.getutc.to_i
        @skip_windows_update = skip_windows_update
        @http_proxy = http_proxy
        @https_proxy = https_proxy
        @bypass_list = bypass_list
        super(args)
      end
    end


    class VSphereAddUpdates < VSphereBase
      def builders
        [
          {
            'type' => 'vmware-vmx',
            'source_path' => @source_path,
            'headless' => false,
            'boot_wait' => '2m',
            'communicator' => 'winrm',
            'winrm_username' => 'Administrator',
            'winrm_password' => @administrator_password,
            'winrm_timeout' => '6h',
            'winrm_insecure' => true,
            'vm_name' =>  'packer-vmx',
            'shutdown_command' => "C:\\Windows\\System32\\shutdown.exe /s",
            'shutdown_timeout' => '1h',
            'vmx_data' => {
              'memsize' => @mem_size.to_s,
              'numvcpus' => @num_vcpus.to_s,
              'displayname' => "packer-vmx-#{@timestamp}"
            },
            'output_directory' => @output_directory
          }
        ]
      end

      def provisioners
        [
          Provisioners::BOSH_PSMODULES,
          Provisioners::NEW_PROVISIONER,
          Provisioners.setup_proxy_settings(@http_proxy, @https_proxy, @bypass_list),
          @skip_windows_update?[]:[Provisioners.install_windows_updates],
          Provisioners::GET_LOG,
          Provisioners::CLEAR_PROXY_SETTINGS,
          Provisioners::CLEAR_PROVISIONER,
          Provisioners::WAIT_AND_RESTART,
          Provisioners::WAIT_AND_RESTART
        ].flatten
      end
    end
    class VSphereVCenter < VSphereBase
      def initialize(product_key:,
                     owner:,
                     organization:,
                     enable_rdp:,
                     new_password:,
                     **args)
        @product_key = product_key
        @owner = owner
        @organization = organization
        @enable_rdp = enable_rdp
        @new_password = new_password
        super(args)
      end

      def builders
        @server = ENV.fetch('VCENTER_SERVER')
        @username = ENV.fetch('VCENTER_USERNAME')
        @password = ENV.fetch('VCENTER_PASSWORD')
        @datacenter = ENV.fetch('VCENTER_DATACENTER')
        enable_rdp = @enable_rdp ? ' -EnableRdp' : ''
        product_key_flag = @product_key.to_s.empty? ? '' : " -ProductKey #{@product_key}"
        [
          'type' => 'vsphere',
          'vcenter_server' => @server,
          'username' => @username,
          'password' => @password,
          'datacenter' => @datacenter,
          'insecure_connection' => 'false',
          'template' => 'scyther/windows1709stemcelltemplate',
          'folder' => 'scyther',
          'shutdown_command' => "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -Command Invoke-Sysprep -IaaS vsphere -NewPassword #{@new_password}#{product_key_flag} -Owner #{@owner} -Organization #{@organization}#{enable_rdp}",
          'shutdown_timeout' => '1h',
          'communicator' => 'winrm',
          'ssh_username' => 'Administrator',
          'ssh_password' => '',
          'winrm_username' => 'Administrator',
          'winrm_password' => '',
          'winrm_timeout' => '1h',
          'winrm_insecure' => true,
          'vm_name' =>  'packer-vcenter',
          'RAM' => '4096',
          'CPUs' => '4',
          'displayname' => "packer-vcenter-#{@timestamp}",
          'skip_clean_files' => true,
          'convert_to_template' => true
        ]
      end

      def provisioners
        pre = [
            Base.pre_provisioners(@os, skip_windows_update: @skip_windows_update, http_proxy: @http_proxy, https_proxy: @https_proxy, bypass_list: @bypass_list),
            Provisioners::lgpo_exe,
            Provisioners.install_agent('vsphere').freeze,
        ]
        download_windows_updates = @skip_windows_update?[]:[Provisioners.download_windows_updates(@output_directory).freeze]

        post = [Base.post_provisioners('vsphere')]

        [pre,
         download_windows_updates,
         post].flatten
      end
    end
    class VSphere < VSphereBase
      def initialize(product_key:,
                     owner:,
                     organization:,
                     enable_rdp:,
                     new_password:,
                     **args)
        @product_key = product_key
        @owner = owner
        @organization = organization
        @enable_rdp = enable_rdp
        @new_password = new_password
        super(args)
      end

      def builders
        enable_rdp = @enable_rdp ? ' -EnableRdp' : ''
        product_key_flag = @product_key.to_s.empty? ? '' : " -ProductKey #{@product_key}"
        [
          'type' => 'vmware-vmx',
          'source_path' => @source_path,
          'headless' => false,
          'boot_wait' => '2m',
          'shutdown_command' => "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -Command Invoke-Sysprep -IaaS vsphere -NewPassword #{@new_password}#{product_key_flag} -Owner #{@owner} -Organization #{@organization}#{enable_rdp}",
          'shutdown_timeout' => '1h',
          'communicator' => 'winrm',
          'ssh_username' => 'Administrator',
          'winrm_username' => 'Administrator',
          'winrm_password' => @administrator_password,
          'winrm_timeout' => '1h',
          'winrm_insecure' => true,
          'vm_name' =>  'packer-vmx',
          'vmx_data' => {
            'memsize' => @mem_size.to_s,
            'numvcpus' => @num_vcpus.to_s,
            'displayname' => "packer-vmx-#{@timestamp}"
          },
          'output_directory' => @output_directory,
          'skip_clean_files' => true
        ]
      end

      def provisioners
        pre = [
            Base.pre_provisioners(@os, skip_windows_update: @skip_windows_update, http_proxy: @http_proxy, https_proxy: @https_proxy, bypass_list: @bypass_list),
            Provisioners::lgpo_exe,
            Provisioners.install_agent('vsphere').freeze,
        ]
        download_windows_updates = @skip_windows_update?[]:[Provisioners.download_windows_updates(@output_directory).freeze]

        post = [Base.post_provisioners('vsphere')]

        [pre,
         download_windows_updates,
         post].flatten
      end
    end
  end
end
