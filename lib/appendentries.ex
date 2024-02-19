
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule AppendEntries do

  def execute_append_request_and_respond_appropriately(server, request) do
    if request.term < server.curr_term do
      server |> ServerLib.send_incorrect_append_entries_reply(request.requester)
    else
      success = request.prev_log_index == 0 || (request.prev_log_index <= Log.last_index(server) and request.prev_log_term == server.log[request.prev_log_index].term)
      index =
        if success do
          server |> store_entries(request.prev_log_index, request.entries, request.commit_index)
        else
          0
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

  # DJQUES: ELSE IF: FIRST PART OF CONDITION <=????
  def process_append_entries_reply(server, reply) do
    if reply.term < server.curr_term or !(server.role == :LEADER) do
      server
    else
      server =
        if reply.success do
          server
          |> State.match_index(reply.followerP, reply.index)
          |> State.next_index(reply.followerP, reply.index + 1)
        else
          server |> State.next_index(reply.followerP, max(1, server.next_index[reply.followerP] - 1))
        end
      server =
        if server.next_index <= Log.last_index(server) do
          server |> ServerLib.send_append_entries(reply.followerP)
        else
          server
        end
      server |> advance_commit_index_if_majority
    end
  end

  defp advance_commit_index_if_majority(server) do
    agreed_indexes = get_agreed_indexes(server)
    new_commit_index =
      if length(agreed_indexes) >= 0 do
        new_commit_index = Enum.max(agreed_indexes)
        if new_commit_index > server.commit_index and Log.term_at(server, new_commit_index) == server.curr_term do
          new_commit_index
        else
          server.commit_index
        end
      else
        server.commit_index
      end
    for index_to_commit <- (server.commit_index + 1)..new_commit_index do
      send server.databaseP, { :DB_REQUEST, Log.entry_at(server, index_to_commit) }
    end
    server |> State.commit_index(new_commit_index)
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
    # DJQUES: WHAT DOES THIS RETURN? COUNT UNUSED?
  end

  defp get_agreed_indexes(server) do
    for index <- 1..Log.last_index(server), quorum_agrees(server, index) do
      index
    end
  end

  defp store_entries(server, prev_log_index, entries, commit_index) do
    # TODO!!!
  end
end # AppendEntries
