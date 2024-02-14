
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
  if term > server.curr_term do
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

# TODO Put the following functions in appendentries.ex?
def send_append_entries_req(server, followerP) do
  send followerP, { :APPEND_ENTRIES_REQUEST, server.curr_term, server.selfP }
  server
end

def send_incorrect_append_entries_response(server, requester) do
  send requester, { :APPEND_ENTRIES_RESPONSE, server.curr_term, false }
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

end # ServerLib
