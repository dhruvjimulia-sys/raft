
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule ServerLib do

def stepdown(server, term) do
  server
  |> Map.put(:curr_term, term)
  |> Map.put(:state, :FOLLOWER)
  |> Map.put(:voted_for, nil)
  |> Timer.restart_election_timer
end

def stepdown_if_current_term_outdated(server, term) do
  if term > server.current_term do
    server |> ServerLib.stepdown(term)
  else
    server
  end
end

def send_append_entries(server, followerP) do
  server
  |> Timer.restart_append_entries_timer(followerP)
  |> ServerLib.send_append_entries_req(followerP)
end

def send_append_entries_req(server, followerP) do
  send followerP, { :APPEND_ENTRIES_REQUEST, server.curr_term, server.selfP }
end

def add_vote_to_voted_by(server, vote, voter) do
  if vote == server.selfP do
    server |> Map.put(:voted_by, MapSet.put(server.voted_by, voter))
  else
    server
  end
end

def make_current_server_leader_if_recd_majority_votes(server) do
  if MapSet.size(server.voted_by) >= server.majority do
    server
    |> Map.put(:role, :LEADER)
    |> Map.put(:leaderP, server.selfP)
    |> send_append_entries_to_all_servers_except_myself
  else
    server
  end
end

def send_append_entries_to_all_servers_except_myself(server) do
  Enum.reduce(server.servers, server, fn acc, followerP ->
    if (followerP != server.selfP) do
      acc |> ServerLib.send_append_entries(followerP)
    else
      acc
    end
  end)
end

end # ServerLib
