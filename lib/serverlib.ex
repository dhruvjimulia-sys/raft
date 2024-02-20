
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule ServerLib do

def stepdown(server, term) do
  server
  |> Debug.stepdown("Server #{server.server_num} is stepping down")
  |> State.curr_term(term)
  |> State.role(:FOLLOWER)
  |> State.voted_for(nil)
  |> Timer.restart_election_timer
end

def stepdown_if_current_term_outdated(server, term) do
  if term > server.curr_term do
    server |> ServerLib.stepdown(term)
  else
    server
  end
end

def stepdown_if_current_term_outdated_or_equal_to(server, term) do
  if term >= server.curr_term do
    server |> ServerLib.stepdown(term)
  else
    server
  end
end

def send_append_entries(server, followerP) do
  server
  |> Debug.sent_append_entries("Server #{server.server_num} sending append entries")
  |> Timer.restart_append_entries_timer(followerP, div(Enum.random(server.config.election_timeout_range), 3))
  |> ServerLib.send_append_entries_req(followerP)
end

# TODO Put the following functions in appendentries.ex?
# DJTODO: next_index should be updated here!
def send_append_entries_req(server, followerP) do
  last_log_index = server.next_index[followerP] - 1
  server = server |> State.next_index(followerP, Log.last_index(server) + 1)
  last_log_term =
    if last_log_index > 0 do
      Log.term_at(server, last_log_index)
    else
      0
    end
  entries = Log.get_entries_from(server, server.next_index[followerP])
  send followerP, { :APPEND_ENTRIES_REQUEST, %{term: server.curr_term, requester: server.selfP, prev_log_term: last_log_term, prev_log_index: last_log_index,
                                                commit_index: server.commit_index, entries: entries} }
  server
end

def send_incorrect_append_entries_reply(server, requester) do
  send requester, { :APPEND_ENTRIES_REPLY, %{term: server.curr_term, success: false, followerP: server.selfP} }
  server
end

def send_append_entries_to_all_servers_except_myself(server) do
  Enum.reduce(server.servers, server, fn followerP, acc ->
    if (followerP != server.selfP) do
      acc |> ServerLib.send_append_entries(followerP)
    else
      acc
    end
  end)
end

def kill_if_leader(server) do
  if server.role == :LEADER do
    kill_leader_log = "Leader server #{server.server_num} was killed by KILL_LEADER"
    Debug.print(server, kill_leader_log)
    Helper.node_halt(kill_leader_log)
  else
    if server.config.repeated_crashing_leaders do
      Process.send_after(self(), { :KILL_LEADER }, server.config.crash_leaders_after)
    end
  end
  server
end

def kill_server(server) do
  kill_server_log = "Server #{server.server_num} was killed by KILL_SERVER"
  Debug.print(server, kill_server_log)
  Helper.node_halt(kill_server_log)
end

def get_server_debug_file_name(server_num) do
  "server#{server_num}.log"
end

end # ServerLib
