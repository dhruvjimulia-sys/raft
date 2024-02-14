
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

  { :APPEND_ENTRIES_REQUEST, term, requester } ->
    server
    |> Debug.received_append_entries_request("Server received append entries request")
    |> ServerLib.stepdown_if_current_term_outdated(term)
    |> AppendEntries.execute_append_request_and_repond_appropriately(term, requester)

  # { :APPEND_ENTRIES_REPLY, ...

  { :APPEND_ENTRIES_TIMEOUT, append_entries_data } ->
    server
    |> Debug.received_append_entries_timeout("Server received append entries timeout")
    |> AppendEntries.handle_append_entries_timeout(append_entries_data)

  { :VOTE_REQUEST, term, candidate } ->
    server
    |> Debug.received_vreq("Server #{server.server_num} received vote request from #{candidate.server_num}")
    |> ServerLib.stepdown_if_current_term_outdated(term)
    |> Vote.vote_for_if_not_already(term, candidate)

  { :VOTE_REPLY, term, vote, voter } ->
    server
    |> Debug.received_vrep("Server #{server.server_num} received vote")
    |> ServerLib.stepdown_if_current_term_outdated(term)
    |> Vote.process_vote(term, vote, voter)

  { :ELECTION_TIMEOUT, timeout_metadata } ->
    server |> Vote.stand_for_election(timeout_metadata)

  # { :CLIENT_REQUEST, ...

   unexpected ->
      Helper.node_halt("***** Server: unexpected message #{inspect unexpected}")
      server
  end # receive

  server |> Server.next()

end # next

end # Server
