require 'rspec/core/rake_task'
require_relative 'lib/stemcell/builder'
import 'lib/tasks/build/aws.rake'
import 'lib/tasks/build/gcp.rake'
import 'lib/tasks/build/vsphere.rake'
import 'lib/tasks/package/agent.rake'
import 'lib/tasks/package/psmodules.rake'

namespace :build do
  desc 'Build AWS Stemcell'
  task :aws do
    puts 'build:azure'
  end

  desc 'Build GCP Stemcell'
  task :gcp do
    puts 'build:gcp'
  end

  desc 'Build VSphere Stemcell'
  task :vsphere do
    puts 'build:vsphere'
  end
end

namespace :package do
  desc 'Package BOSH Agent and dependencies into agent.zip'
  task :agent do
    puts 'package:agent'
  end
  desc 'Package BOSH psmodules into bosh-psmodules.zip'
  task :psmodules do
    puts 'package:psmodules'
  end
  desc 'Package VSphere OVA files into Stemcells'
  task :vsphere do
    puts 'package:vsphere_ova'
  end
end
