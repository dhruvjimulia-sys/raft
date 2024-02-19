
# distributed algorithms, n.dulay, 14 jan 2024
# coursework, raft consensus, v2

defmodule ClientRequest do
  def process_client_request(server, client_req) do
    if server.role == :LEADER do
      server
      |> server.log.append_entry(client_req)
      |> ServerLib.send_append_entries_to_all_servers_except_myself
    else
      send client_command.clientP, { :CLIENT_REPLY, %{cid: client_command.cid, reply: :NOT_LEADER, leaderP: server.leaderP} }
      server
    end
  end

  def return_db_result(server, db_result) do
    send db_result.clientP, { :CLIENT_REPLY, %{cid: db_result.cid, reply: db_result.reply, leaderP: server.leaderP} }
    server
  end


end # ClientRequest
