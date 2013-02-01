maintainer       "Gourav Shah"
maintainer_email "gs@initcron.org"
license          "Apache 2.0"
description      "Installs/Configures zookeeper"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "1.0"

recipe "zookeeper::ebs_volume", "Attaches or creates an EBS volume for zookeeper"

%w{ debian ubuntu }.each do |os|
  supports os
end

depends "java"
depends "runit"
depends "hadoop"
