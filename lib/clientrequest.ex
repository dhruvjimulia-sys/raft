
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2
# Dhruv Jimulia (dj321) and Adi Prasad (arp21)

defmodule ClientRequest do
  def process_client_request(server, client_req) do
    if server.role == :LEADER do
      duplicate = Enum.find(server.log, fn {_, entry} -> entry.request.cid == client_req.cid end)
      if duplicate do
        server
      else
        send server.config.monitorP, { :CLIENT_REQUEST, server.server_num }
        server
        |> Debug.appended_entry("Server #{server.server_num} appended #{inspect client_req.cmd}")
        |> Log.append_entry(%{term: server.curr_term, request: client_req})
        |> ServerLib.send_append_entries_to_all_servers_except_myself
      end
    else
      send client_req.clientP, { :CLIENT_REPLY, %{cid: client_req.cid, reply: :NOT_LEADER, leaderP: server.leaderP} }
      server
    end
  end

  def return_db_result(server, db_result) do
    send db_result.clientP, { :CLIENT_REPLY, %{cid: db_result.cid, reply: db_result, leaderP: server.leaderP} }
    server
  end


end # ClientRequest
