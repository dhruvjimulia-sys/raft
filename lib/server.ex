
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
    server |> ServerLib.stepdown_if_current_term_outdated(term)
    if term < server.curr_term do
      server |> ServerLib.send_incorrect_append_entries_response(requester)
    else
      server
    end

  # { :APPEND_ENTRIES_REPLY, ...

  { :APPEND_ENTRIES_TIMEOUT, append_entries_data } ->
    if server.role == :CANDIDATE do
      send append_entries_data.followerP, { :VOTE_REQUEST, server.curr_term, server.selfP }
      Timer.restart_append_entries_timer(server, append_entries_data.followerP)
    else
      server
    end

  { :VOTE_REQUEST, term, candidate } = msg ->
    server
    |> Debug.received(msg)
    |> ServerLib.stepdown_if_current_term_outdated(term)
    |> Vote.vote_for_if_not_already(term, candidate)

  { :VOTE_REPLY, term, vote, voter } ->
    server
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
