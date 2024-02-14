
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule AppendEntries do

  def execute_append_request_and_respond_appropriately(server, term, requester) do
    if term < server.curr_term do
      server |> ServerLib.send_incorrect_append_entries_reply(requester)
    else
      # store entries to log if sucessful
      server
    end
  end

  def if_candidate_send_votereq(server, append_entries_data) do
    if server.role == :CANDIDATE do
      send append_entries_data.followerP, { :VOTE_REQUEST, server.curr_term, server }
      server
      |> Debug.send_vote_request("Server #{server.server_num} sent vote request")
      |> Timer.restart_append_entries_timer(append_entries_data.followerP, server.config.append_entries_timeout)
    else
      server
    end
  end

  def if_leader_send_append_entries(server, append_entries_data) do
    if server.role == :LEADER do
      server |> ServerLib.send_append_entries(append_entries_data.followerP)
    else
      server
    end
  end
end # AppendEntries
