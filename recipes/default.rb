#
# Cookbook Name:: zookeeper
# Recipe:: default
#
# Copyright 2010, GoTime Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "java"
include_recipe "runit"

case "#{node.install.type}"
when "remote"
  remote_file "/opt/zookeeper-#{node[:zookeeper][:version]}.tar.gz" do
    source "#{node[:zookeeper][:mirror]}/zookeeper-#{node[:zookeeper][:version]}/zookeeper-#{node[:zookeeper][:version]}.tar.gz"
    mode "0644"
    action :create_if_missing
  end
when "local"
  cookbook_file "/opt/zookeeper-#{node[:zookeeper][:version]}.tar.gz" do
    source "artifacts/zookeeper-#{node[:zookeeper][:version]}.tar.gz"
    mode "0644"
    action :create_if_missing
  end
end

group "zookeeper" do
  action :create
end

user "zookeeper" do
  home "/home/zookeeper"
  shell "/bin/bash"
  gid "zookeeper"
  action :create
end

bash "untar zookeeper" do
  user "root"
  cwd "/opt"
  code %(tar zxf /opt/zookeeper-#{node[:zookeeper][:version]}.tar.gz)
  not_if { File.exists? "/opt/zookeeper-#{node[:zookeeper][:version]}" }
end

bash "chown zookeeper" do
  user "root"
  cwd "/opt"
  code %(chown -R zookeeper:zookeeper /opt/zookeeper-#{node[:zookeeper][:version]})
end

directory "/opt/zookeeper-#{node[:zookeeper][:version]}/log" do                                                                                                                     
  owner "zookeeper"                                                                                                                                
  group "zookeeper"                                                                                                                                  
  mode 0755                                                                                                                                        
end            

#bash "copy zk root" do
#  user "root"
#  cwd "/opt"
#  code %(cp -r /opt/zookeeper-#{node[:zookeeper][:version]}/* /usr/lib/zookeeper-#{node[:zookeeper][:version]})
#  not_if { File.exists? "/usr/lib/zookeeper-#{node[:zookeeper][:version]}/lib" }
#end

#link "/usr/lib/zookeeper" do
#  to "/usr/lib/zookeeper-#{node[:zookeeper][:version]}"
#end

#bash "copy zk conf" do
#  user "root"
#  cwd "/usr/lib/zookeeper"
#  code %(cp -R ./conf/* /etc/zookeeper)
#  not_if { File.exists? "/etc/zookeeper/log4j.properties" }
#end

template "/opt/zookeeper-#{node[:zookeeper][:version]}/conf/log4j.properties" do
  source "log4j.properties.erb"
  mode 0644
end

zk_servers = [node]
if !node.chef.solo
  zk_servers += search(:node, "role:zookeeper AND chef_environment:#{node.chef_environment} NOT name:#{node.name}") # don't include this one, since it's already in the list
  zk_servers.sort! { |a, b| a.name <=> b.name }
end

template "/opt/zookeeper-#{node[:zookeeper][:version]}/conf/zoo.cfg" do
  source "zoo.cfg.erb"
  mode 0644
  variables(:servers => zk_servers)
end

## ebs_volume recipe is been commented for initial testing. 
## add it when ec2 support is added. 
## this needs additional recipes e.g. aws, xfs and ebs-snapshots, see ebs_volume.rb for details
## Include_recipe "zookeeper::ebs_volume"

directory node[:zookeeper][:data_dir] do
  recursive true
  owner "zookeeper"
  group "zookeeper"
  mode 0755
end

myid = zk_servers.collect { |n| n[:ipaddress] }.index(node[:ipaddress])

template "#{node[:zookeeper][:data_dir]}/myid" do
  source "myid.erb"
  owner "zookeeper"
  group "zookeeper"
  variables(:myid => myid)
end

if platform?("ubuntu")

runit_service "zookeeper"
service "zookeeper" do
  subscribes :restart, resources(:template => "/opt/zookeeper-#{node[:zookeeper][:version]}/conf/zoo.cfg")
end
end

if platform?("redhat", "centos", "fedora")
  template "/etc/init.d/zookeeper" do
    source "zookeeper.init"
    owner "root"
    group "root"
    mode 0755
  end

  service "zookeeper" do
    service_name "zookeeper"
    pattern "zookeeper"
    start_command "/etc/init.d/zookeeper start"
    stop_command "/etc/init.d/zookeeper stop"
    status_command "ps auwwx | grep zookeeper | grep -v grep"
    restart_command"/etc/init.d/zookeeper stop && sleep 10 && /etc/init.d/zookeeper start"
    action [ :enable, :start ]
    supports :start => true, :stop => true, :restart => true, :status => true, :reload => false
    subscribes :restart, resources(:template => "/opt/zookeeper-#{node[:zookeeper][:version]}/conf/zoo.cfg")
  end
end

