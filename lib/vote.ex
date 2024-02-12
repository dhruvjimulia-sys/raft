
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule Vote do
  def stand_for_election(server, timeout_metadata) do
    case server.role == :LEADER or server.role == :CANDIDATE do
      true ->
        server = server
          |> Timer.restart_election_timer()
          |> Map.put(:curr_term, server.curr_term + 1)
          |> Map.put(:role, :CANDIDATE)
          |> Map.put(:voted_for, self())
          |> Map.put(:voted_by, MapSet.new([self()]))
          |> Timer.cancel_all_append_entries_timers
        for server <- server.servers do
          # this needs to be restart_election_timer()! in hindsight!
          timeout_msg = { :ELECTION_TIMEOUT, %{term: server.curr_term, election: server.curr_election} }
          send server, timeout_msg
        end
        server
      false ->
        server
    end
  end
end # Vote
