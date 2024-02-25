
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2
# Dhruv Jimulia (dj321) and Adi Prasad (arp21)

defmodule Server do
# _________________________________________________________ Server.start()
def start(config, server_num) do

  config = config
    |> Configuration.node_info("Server", server_num)
    |> Debug.node_starting()

  # handle crashing as described in config
  if config.crash_leaders_after !== nil do
    Process.send_after(self(), { :KILL_LEADER }, config.crash_leaders_after)
  end
  crash_time = Map.get(config.crash_servers, server_num)
  if crash_time !== nil do
    Process.send_after(self(), { :KILL_SERVER }, crash_time)
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
    server |> ServerLib.kill_if_leader

  { :KILL_SERVER } ->
    server |> ServerLib.kill_server

  { :APPEND_ENTRIES_REQUEST, append_entries_request_data } ->
    server
    |> Debug.received_append_entries_request("Server #{server.server_num} received append entries request #{inspect append_entries_request_data.entries}")
    |> ServerLib.stepdown_if_current_term_outdated_or_equal_to(append_entries_request_data.term)
    |> Timer.restart_election_timer
    |> AppendEntries.execute_append_request_and_respond_appropriately(append_entries_request_data)

  { :APPEND_ENTRIES_REPLY, append_entries_reply_data } ->
    server
    |> Debug.received_append_entries_reply("Server #{server.server_num} received append entries reply")
    |> ServerLib.stepdown_if_current_term_outdated(append_entries_reply_data.term)
    |> AppendEntries.process_append_entries_reply(append_entries_reply_data)

  { :APPEND_ENTRIES_TIMEOUT, append_entries_data } ->
    server
    |> Debug.received_append_entries_timeout("Server #{server.server_num} received append entries timeout")
    |> Vote.if_candidate_send_votereq(append_entries_data)
    |> AppendEntries.if_leader_send_append_entries(append_entries_data)

  { :VOTE_REQUEST, vote_request_data } ->
    server
    |> ServerLib.stepdown_if_current_term_outdated(vote_request_data.term)
    |> Vote.vote_for_if_not_already(vote_request_data)

  { :VOTE_REPLY, vote_reply_data } ->
    server
    |> Debug.received_vrep("Server #{server.server_num} received vote")
    |> ServerLib.stepdown_if_current_term_outdated(vote_reply_data.term)
    |> Vote.process_vote(vote_reply_data.term, vote_reply_data.vote, vote_reply_data.voter)

  { :ELECTION_TIMEOUT, timeout_metadata } ->
    server
    |> Debug.received_etim("Server #{server.server_num} received election timeout")
    |> Vote.stand_for_election(timeout_metadata)

  { :CLIENT_REQUEST, client_req } ->
    server
    |> Debug.received_client_request("Server #{server.server_num} received client request cid: #{inspect client_req.cid}")
    |> ClientRequest.process_client_request(client_req)

  { :DB_REPLY, {:OK, db_result }} ->
    server
    |> Debug.received_db_reply("Server #{server.server_num} received db reply")
    |> ClientRequest.return_db_result(db_result)

   unexpected ->
      Helper.node_halt("***** Server: unexpected message #{inspect unexpected}")
      server
  end # receive

  server |> Server.next()

end # next

end # Server
