
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

end # ServerLib
