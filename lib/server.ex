
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule Server do
# _________________________________________________________ Server.start()
def start(config, server_num) do

  config = config
    |> Configuration.node_info("Server", server_num)
    |> Debug.node_starting()

  if config.crash_leaders_after !== nil do
    Process.send_after(self(), { :KILL_LEADER }, config.crash_leaders_after)
  end

  File.rm(ServerLib.get_server_debug_file_name(server_num))

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

  { :KILL_LEADER } ->
    server
    |> ServerLib.kill_if_leader

  { :APPEND_ENTRIES_REQUEST, term, requester } ->
    server
    |> Debug.received_append_entries_request("Server #{server.server_num} received append entries request")
    |> ServerLib.stepdown_if_current_term_outdated_or_equal_to(term)
    |> Timer.restart_election_timer
    |> AppendEntries.execute_append_request_and_respond_appropriately(term, requester)

  { :APPEND_ENTRIES_REPLY, term, _success, _index } ->
    server
    |> Debug.received_append_entries_reply("Server #{server.server_num} received append entries reply")
    |> ServerLib.stepdown_if_current_term_outdated(term)

  { :APPEND_ENTRIES_TIMEOUT, append_entries_data } ->
    server
    |> Debug.received_append_entries_timeout("Server #{server.server_num} received append entries timeout")
    |> AppendEntries.if_candidate_send_votereq(append_entries_data)
    |> AppendEntries.if_leader_send_append_entries(append_entries_data)

  { :VOTE_REQUEST, term, candidate } ->
    server
    |> ServerLib.stepdown_if_current_term_outdated(term)
    |> Vote.vote_for_if_not_already(term, candidate)

  { :VOTE_REPLY, term, vote, voter } ->
    server
    |> Debug.received_vrep("Server #{server.server_num} received vote")
    |> ServerLib.stepdown_if_current_term_outdated(term)
    |> Vote.process_vote(term, vote, voter)

  { :ELECTION_TIMEOUT, timeout_metadata } ->
    server
    |> Debug.received_etim("Server #{server.server_num} received election timeout")
    |> Vote.stand_for_election(timeout_metadata)

  { :CLIENT_REQUEST, _client_request_data } ->
    server

   unexpected ->
      Helper.node_halt("***** Server: unexpected message #{inspect unexpected}")
      server
  end # receive

  server |> Server.next()

end # next

end # Server
