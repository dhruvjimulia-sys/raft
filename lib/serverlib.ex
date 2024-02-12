
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule ServerLib do

# Library of functions called by other server-side modules
def set_timeout() do

end

def stepdown(server, term) do
  server
  |> Map.put(:curr_term, term)
  |> Map.put(:state, :FOLLOWER)
  |> Map.put(:voted_for, nil)
  # incomplete!
end

def stepdown_if_current_term_outdated(server, term) do
  if term > server.current_term do
    server |> ServerLib.stepdown(term)
  else
    server
  end
end

def vote_for_if_not_already(server, term, q) do
  if term == server.curr_term and server.voted_for in {q, nil} do
    server
    |> Map.put(:voted_for, q)
    |> Timer.restart_election_timer
    |> send_vote_reply(term, q)
  else
    server
  end
end

defp send_vote_reply(server, term, q) do
  vote_reply_msg = { :VOTE_REPLY, term, server.voted_for, server.selfP }
  send q, vote_reply_msg
  server
end

end # ServerLib
