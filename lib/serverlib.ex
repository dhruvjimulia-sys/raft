
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

end # ServerLib
