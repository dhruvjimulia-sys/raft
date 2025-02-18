
# distributed algorithms, n.dulay, 14 jan 2024
# raft, configuration parameters v2
# Dhruv Jimulia (dj321) and Adi Prasad (arp21)
# add repeated_crashing_leaders, per_server_file_logging to config params

defmodule Configuration do

# _________________________________________________________ node_init()
def node_init() do
  # get node arguments and spawn a process to exit node after max_time
  config =
  %{
    node_suffix:     Enum.at(System.argv, 0),
    raft_timelimit:  String.to_integer(Enum.at(System.argv, 1)),
    debug_level:     String.to_integer(Enum.at(System.argv, 2)),
    debug_options:   "#{Enum.at(System.argv, 3)}",
    n_servers:       String.to_integer(Enum.at(System.argv, 4)),
    n_clients:       String.to_integer(Enum.at(System.argv, 5)),
    params_function: :'#{Enum.at(System.argv, 6)}',
    start_function:  :'#{Enum.at(System.argv, 7)}',
  }

  if config.n_servers < 3 do
    Helper.node_halt("Raft is unlikely to work with fewer than 3 servers")
  end # if

  spawn(Helper, :node_exit_after, [config.raft_timelimit])

  config |> Map.merge(Configuration.params(config.params_function))
end # node_init

# _________________________________________________________ node_info()
def node_info(config, node_type, node_num \\ "") do
  Map.merge config,
  %{
    node_type:     node_type,
    node_num:      node_num,
    node_name:     "#{node_type}#{node_num}",
    node_location: Helper.node_string(),
    line_num:      0,  # for ordering output lines
  }
end # node_info

# _________________________________________________________ params :default ()
def params :default do
  %{
    n_accounts:              100,      # account numbers 1 .. n_accounts
    max_amount:              1_000,    # max amount moved between accounts in a single transaction

    client_timelimit:        60_000,   # clients stops sending requests after this time(ms)
    max_client_requests:     5000,     # maximum no of requests each client will attempt
    client_request_interval: 1,        # interval(ms) between client requests
    client_reply_timeout:    50,       # timeout(ms) for the reply to a client request

    election_timeout_range:  100..200, # timeout(ms) for election, set randomly in range
    append_entries_timeout:  10,       # timeout(ms) for the reply to a append_entries request

    monitor_interval:        1000,     # interval(ms) between monitor summaries

    crash_servers: %{		       # server_num => crash_after_time (ms), ..
      # 3 => 5_000,
      # 4 => 8_000,
    },

    crash_leaders_after:      nil,    # nil or time after which leaders will crash

    repeated_crashing_leaders: true,   # if true, will crash leaders repeatedly EVERY crash_leaders_after ms
    per_server_file_logging:  true     # if true, gives per-server logging info in separate files
  }
end # params :default


# add further params functions for your own tests and experiments

def params :server_one_crash do
  Map.merge (params :default),
  %{
    crash_servers: %{
      1 => 5_000
    }
  }
end

def params :leader_crash do
  Map.merge (params :default),
  %{
    crash_leaders_after: 5_000,
    repeated_crashing_leaders: false
  }
end

def params :repeated_crashing_leaders do
  Map.merge (params :default),
  %{
    crash_leaders_after: 3_000,
    repeated_crashing_leaders: true
  }
end

def params :election_timeout_one do
  Map.merge (params :default),
  %{
    election_timeout_range: 100..500,
  }
end

def params :election_timeout_two do
  Map.merge (params :default),
  %{
    election_timeout_range: 500..1000,
  }
end

def params :election_timeout_three do
  Map.merge (params :default),
  %{
    election_timeout_range: 1000..5000,
  }
end

end # Configuration













"""
def read_host_map(file_name) do      # read map of hosts for fully distributed execution via ssh
  # Format of lines
  #    line = <nodenum> <hostname> pair
  # returns Map of nodenum to hostname

  stream = File.stream!(file_name) |> Stream.map(&String.split/1)

  for [first, second | _] <- stream, into: Map.new do
    { (first |> String.to_integer), second }
  end # for
end # read_host_map
"""
