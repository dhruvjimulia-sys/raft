
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule AppendEntries do

  def execute_append_request_and_respond_appropriately(server, request) do
    if request.term < server.curr_term do
      server |> ServerLib.send_incorrect_append_entries_reply(request.requester)
    else
      index = 0
      success = request.prev_log_index == 0 || (request.prev_log_index <= server.log.length and request.prev_log_term == server.log[request.prev_log_index].term)
      if success do
        index = server |> store_entries(request.prev_log_index, request.entries, request.commit_index)
      end
      send request.requester, { :APPEND_ENTRIES_REPLY, %{term: server.curr_term, success: success, index: index} }
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

  def advance_commit_index_if_majority(server, append_entries_reply_data) do
    server |> assert(server.role == :LEADER, "advance_commit_index_if_majority: server.role != :LEADER")
    agreed_indexes = get_agreed_indexes(server)
    new_commit_index =
      if length(agreed_indexes) >= 0 do
        new_commit_index = max(agreed_indexes)
        if new_commit_index > server.commit_index and server.log.term_at(new_commit_index) == server.curr_term do
          new_commit_index
        else
          server.commit_index
        end
      else
        server.commit_index
      end
    for index_to_commit <- server.commit_index + 1..new_commit_index do
      send server.databaseP, { :DB_REQUEST, server.log.entry_at(server, index_to_commit) }
    end
    server.commit_index = new_commit_index
    server
  end

  defp quorum_agrees(server, index) do
    count = for followerP <- server.servers, reduce: 0 do
      acc ->
        if Map.get(server.match_index, followerP) >= index or followerP == server.selfP do
          acc + 1
        else
          acc
        end
    end
  end

  defp get_agreed_indexes(server) do
    for index <- 1..server.log.last_index(server), quorum_agrees(server, index) do
      index
    end
  end
end # AppendEntries
