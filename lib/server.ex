
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule Server do
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

  { :APPEND_ENTRIES_TIMEOUT, append_entries_data } ->
    # append_entries_data: %{term: server.curr_term, followerP: followerP }
    if server.role == :CANDIDATE do
      send append_entries_data.followerP.selfP, { :VOTE_REQUEST, server.currentTerm, server.selfP }
      Timer.restart_append_entries_timer(server, append_entries_data.followerP)
    else
      server
    end

  { :VOTE_REQUEST, term, candidate } ->
    server
    |> ServerLib.stepdown_if_current_term_outdated(term)
    |> Vote.vote_for_if_not_already(term, candidate)

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
