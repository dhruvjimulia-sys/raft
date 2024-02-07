
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule Vote do
  def stand_for_election(server, timeout_metadata) do
    if server.role == :LEADER or server.role == :CANDIDATE, do:
      server = server
        |> Timer.restart_election_timer()
        |> Map.put(:curr_term, server.curr_term + 1)
        |> Map.put(:role, :CANDIDATE)
        |> Map.put(:voted_for, self())
        |> Map.put(:voted_by, MapSet.new([self()]))

      for other_server <- server.servers do
        if other_server != self() do
          Timer.cancel_election_timer(server)

          send other_server, { :VOTE_REQUEST, server.curr_term }
        end
      end
  end

end # Vote
