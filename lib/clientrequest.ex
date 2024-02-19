
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2


defmodule ClientRequest do
  def process_client_request(server, client_req) do
    if server.role == :LEADER do
      duplicate = Enum.find(server.log, fn entry -> entry.cid == client_req.cid end)
      if duplicate do
        send client_req.clientP, { :CLIENT_REPLY, %{cid: client_req.cid, reply: duplicate, leaderP: server.leaderP} }
        server
      else
        server
        |> Log.append_entry(client_req)
        |> ServerLib.send_append_entries_to_all_servers_except_myself
      end
    else
      # DJQUES: client_req, and not client_command?
      send client_req.clientP, { :CLIENT_REPLY, %{cid: client_req.cid, reply: :NOT_LEADER, leaderP: server.leaderP} }
      server
    end
  end

  def return_db_result(server, db_result) do
    send db_result.clientP, { :CLIENT_REPLY, %{cid: db_result.cid, reply: db_result.reply, leaderP: server.leaderP} }
    server
  end


end # ClientRequest
