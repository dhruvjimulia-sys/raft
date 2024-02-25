
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2
# Dhruv Jimulia (dj321) and Adi Prasad (arp21)

defmodule Vote do
  # _________________________________________________________ restart_all_append_entries_timers()
  def start_all_append_entries_timers_immediately(server) do
    for followerP <- server.servers do
      timeout_msg = { :APPEND_ENTRIES_TIMEOUT, %{term: server.curr_term, followerP: followerP }}
      send server.selfP, timeout_msg
    end
    server
  end

  def stand_for_election(server, _timeout_metadata) do
    if server.role == :FOLLOWER or server.role == :CANDIDATE do
      server
        |> Debug.stood_for_election("Server #{server.server_num} stood for election")
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

  def if_candidate_send_votereq(server, append_entries_data) do
    if server.role == :CANDIDATE do
      send append_entries_data.followerP, { :VOTE_REQUEST, %{ term: server.curr_term, candidate: server,
                                                              last_log_index: Log.last_index(server), last_log_term: Log.last_term(server)} }
      server
      |> Debug.send_vote_request("Server #{server.server_num} sent vote request")
      |> Timer.restart_append_entries_timer(append_entries_data.followerP, server.config.append_entries_timeout)
    else
      server
    end
  end

  def vote_for_if_not_already(server, vote_req) do
    vote_is_more_complete = vote_req.last_log_term < Log.last_term(server) or
                            (vote_req.last_log_term == Log.last_term(server) and vote_req.last_log_index < Log.last_index(server))
    if vote_req.term == server.curr_term and server.voted_for in MapSet.new([vote_req.candidate.selfP, nil]) and !vote_is_more_complete do
      server
      |> Map.put(:voted_for, vote_req.candidate.selfP)
      |> Timer.restart_election_timer
      |> send_vote_reply(vote_req.term, vote_req.candidate.selfP)
    else
      server
    end
  end

  defp send_vote_reply(server, term, candidate) do
    vote_reply_msg = { :VOTE_REPLY, %{term: term, vote: server.voted_for, voter: server.selfP} }
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
      |> Debug.become_leader("Server #{server.server_num} became leader")
      |> Map.put(:role, :LEADER)
      |> Map.put(:leaderP, server.selfP)
      |> ServerLib.send_append_entries_to_all_servers_except_myself
    else
      server
    end
  end
end # Vote
