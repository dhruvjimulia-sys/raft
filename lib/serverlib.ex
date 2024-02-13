
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

def vote_for_if_not_already(server, term, candidate) do
  if term == server.curr_term and server.voted_for in {candidate, nil} do
    server
    |> Map.put(:voted_for, candidate)
    |> Timer.restart_election_timer
    |> send_vote_reply(term, candidate)
  else
    server
  end
end

defp send_vote_reply(server, term, candidate) do
  vote_reply_msg = { :VOTE_REPLY, term, server.voted_for, server.selfP }
  send candidate, vote_reply_msg
  server
end

end # ServerLib
