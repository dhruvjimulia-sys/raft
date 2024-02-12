
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule Server do
  defp stepdown(server, term) do
    server
    |> Map.put(:curr_term, term)
    |> Map.put(:state, :FOLLOWER)
    |> Map.put(:voted_for, nil)
    # incomplete!
  end
# _________________________________________________________ Server.start()
def start(config, server_num) do

  config = config
    |> Configuration.node_info("Server", server_num)
    |> Debug.node_starting()

  receive do
  { :BIND, servers, databaseP } ->
    config
    |> State.initialise(server_num, servers, databaseP)
    |> Timer.restart_election_timer()
    |> Server.next()
  end # receive
end # start

# _________________________________________________________ next()
def next(server) do

  # invokes functions in AppendEntries, Vote, ServerLib etc

  server = receive do

  # { :APPEND_ENTRIES_REQUEST, ...

  # { :APPEND_ENTRIES_REPLY, ...

  { :APPEND_ENTRIES_TIMEOUT, } ->
    if server. = :CANDIDATE do
      # set hRpcTimeout, qi at now() + vote
      # send { :VOTE_REQUEST, server.currentTerm}, q
    end

  # { :VOTE_REQUEST, term } ->
    # incomplete!

  # { :VOTE_REPLY, term, vote, q } ->
    # incomplete!

  { :ELECTION_TIMEOUT, timeout_metadata } ->
    server |> Vote.stand_for_election(timeout_metadata)

  # { :CLIENT_REQUEST, ...

   unexpected ->
      Helper.node_halt("***** Server: unexpected message #{inspect unexpected}")

  end # receive

  server |> Server.next()

end # next

end # Server
