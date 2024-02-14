
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

  # TODO Replace Map.puts by corresponding functions in state.ex
  # TODO why is timeout_metadata.curr_election required? - edstem
  # TODO timeout_metadata unused?
  # TODO Debug.assert(server, server.curr_term == timeout_metadata.curr_term, "Server current term must be the same as the one passed in timeout_metadata")
  def stand_for_election(server, _timeout_metadata) do
    if server.role == :FOLLOWER or server.role == :CANDIDATE do
      server
        |> Debug.print("Server #{server.server_num} stood for election")
        |> Timer.restart_election_timer()
        |> Map.put(:curr_term, server.curr_term + 1)
        |> Map.put(:role, :CANDIDATE)
        |> Map.put(:voted_for, self())
        |> Map.put(:voted_by, MapSet.new([self()]))
        |> Timer.cancel_all_append_entries_timers
        |> start_all_append_entries_timers_immediately
    else
        server
    end
  end

  def vote_for_if_not_already(server, term, candidate) do
    if term == server.curr_term and server.voted_for in MapSet.new([candidate.selfP, nil]) do
      server
      |> Map.put(:voted_for, candidate.selfP)
      |> Timer.restart_election_timer
      |> send_vote_reply(term, candidate.selfP)
    else
      server
    end
  end

  defp send_vote_reply(server, term, candidate) do
    vote_reply_msg = { :VOTE_REPLY, term, server.voted_for, server.selfP }
    send candidate, vote_reply_msg
    server
  end

  def process_vote(server, term, vote, voter) do
    if term == server.curr_term and server.role == :CANDIDATE do
      server
      |> Vote.add_vote_to_voted_by_if_vote_is_for_self(vote, voter)
      |> Timer.cancel_append_entries_timer(voter)
      |> Vote.make_current_server_leader_if_recd_majority_votes
    else
      server
    end
  end

  def add_vote_to_voted_by_if_vote_is_for_self(server, vote, voter) do
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
      |> ServerLib.send_append_entries_to_all_servers_except_myself
    else
      server
    end
  end
end # Vote
