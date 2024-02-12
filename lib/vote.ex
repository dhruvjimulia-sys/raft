
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule Vote do
  # _________________________________________________________ restart_all_append_entries_timers()
  def start_all_append_entries_timers_immediately(server) do
    for followerP <- server.servers do
      timeout_msg = { :APPEND_ENTRIES_TIMEOUT, %{term: server.curr_term, followerP: followerP }}
      send server.selfP, timeout_msg
    end
    server
  end

  def stand_for_election(server, timeout_metadata) do
    # timeout_metadata: %{term: server.curr_term, election: server.curr_election}
    case server.role == :LEADER or server.role == :CANDIDATE do
      true ->
        server
          |> Timer.restart_election_timer()
          |> Map.put(:curr_term, server.curr_term + 1)
          |> Map.put(:role, :CANDIDATE)
          |> Map.put(:voted_for, self())
          |> Map.put(:voted_by, MapSet.new([self()]))
          |> Timer.cancel_all_append_entries_timers
          |> start_all_append_entries_timers_immediately
      false ->
        server
    end
  end
end # Vote
