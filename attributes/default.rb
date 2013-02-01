#include_attribute "hadoop"

set_unless[:zookeeper][:cluster_name] = "zookeeper"

# ZK defaults
set_unless[:zookeeper][:tick_time]    = 2000
set_unless[:zookeeper][:init_limit]   = 10
set_unless[:zookeeper][:sync_limit]   = 5
set_unless[:zookeeper][:client_port]  = 2181
set_unless[:zookeeper][:peer_port]    = 2888
set_unless[:zookeeper][:leader_port]  = 3888
set_unless[:zookeeper][:version]      = "3.4.3"
set_unless[:zookeeper][:dir]          = "/opt/zookeeper-3.4.3"
set_unless[:zookeeper][:data_dir]     = "/opt/zookeeper-3.4.3/data"

set_unless[:zookeeper][:mirror]       = "http://archive.apache.org/dist/zookeeper"
#set_unless[:zookeeper][:version]    =

set_unless[:zookeeper][:ebs_vol_dev]  = "/dev/sdp"
set_unless[:zookeeper][:ebs_vol_size] = 150
