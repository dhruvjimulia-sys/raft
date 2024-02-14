
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule AppendEntries do

  def execute_append_request_and_repond_appropriately(server, term, requester) do
    if term < server.curr_term do
      server |> ServerLib.send_incorrect_append_entries_response(requester)
    else
      # store entries to log if sucessful
      server
    end
  end

  def handle_append_entries_timeout(server, append_entries_data) do
    if server.role == :CANDIDATE do
      # TODO Refactor send out into a function
      send append_entries_data.followerP, { :VOTE_REQUEST, server.curr_term, server }
      server
      |> Debug.send_vote_request("Server #{server.server_num} sent vote request")
      |> Timer.restart_append_entries_timer(append_entries_data.followerP)
    else
      server
    end
  end

end # AppendEntries
