
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule AppendEntries do

  def execute_append_request_and_respond_appropriately(server, request) do
    if request.term < server.curr_term do
      server |> ServerLib.send_incorrect_append_entries_reply(request.requester)
    else
      success = request.prev_log_index == 0 || (request.prev_log_index <= Log.last_index(server) and request.prev_log_term == server.log[request.prev_log_index].term)
      { server, index } =
        if success do
          server |> store_entries(request.prev_log_index, request.entries, request.commit_index)
        else
          {server, 0}
        end
      send request.requester, { :APPEND_ENTRIES_REPLY, %{term: server.curr_term, success: success, followerP: server.selfP, index: index} }
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

  # What about match_index in the else case below?
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
      if length(agreed_indexes) > 0 do
        new_commit_index = Enum.max(agreed_indexes)
        if new_commit_index > server.commit_index and Log.term_at(server, new_commit_index) == server.curr_term do
          new_commit_index
        else
          server.commit_index
        end
      else
        server.commit_index
      end
    server
    |> commit_all_entries_till_commit_index(new_commit_index)
    |> State.commit_index(new_commit_index)
  end

  # DJTODO: IS THIS THE INTENDED BEHAVIOUR?
  defp quorum_agrees(server, index) do
    count = for followerP <- server.servers, reduce: 0 do
      acc ->
        if Map.get(server.match_index, followerP) >= index or followerP == server.selfP do
          acc + 1
        else
          acc
        end
    end
    count >= server.majority
  end

  defp get_agreed_indexes(server) do
    for index <- 1..Log.last_index(server), quorum_agrees(server, index) do
      index
    end
  end

  defp append_entries_to_log(server, entries) do
    Enum.reduce(entries, server, fn {_, entry}, acc ->
      acc
      |> Debug.appended_entry("Server #{acc.server_num} appended #{inspect entry.request.cid} (append entries)")
      |> Log.append_entry(entry)
    end)
  end

  defp commit_all_entries_till_commit_index(server, commit_index) do
    if commit_index > server.commit_index do
      for index_to_commit <- (server.commit_index + 1)..commit_index do
        send server.databaseP, { :DB_REQUEST, Log.request_at(server, index_to_commit) }
      end
    end
    server
  end

  # TODO: cannot pipeline the following!!! keep it as it is!!
  defp store_entries(server, prev_log_index, entries, commit_index) do
    server = server
    |> Debug.store_entries("Server #{server.server_num} to store entries #{inspect entries}")
    |> Log.delete_entries(prev_log_index + 1..Log.last_index(server))
    server = server |> append_entries_to_log(entries)
    server = server
    |> Debug.appended_entry("After appending entries, resulting log is #{inspect Log.get_entries_from(server, 1)}")
    |> commit_all_entries_till_commit_index(min(commit_index, prev_log_index + map_size(entries)))
    |> State.commit_index(min(commit_index, prev_log_index + map_size(entries)))
    { server, prev_log_index + map_size(entries) }
  end
end # AppendEntries
