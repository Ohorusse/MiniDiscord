Code start 1ere partie:

def start(host, port) do
        case :gen_tcp.connect(String.to_charlist(host), port, [:binary, packet: :line, active: false]) do
          {:ok, socket} ->
            IO.puts("Connecté au serveur #{host}:#{port}")
    
            rencontre(socket)
    
            receiver = Task.async(fn -> receive_loop(socket) end)
            sender = Task.async(fn -> send_loop(socket) end)
    
            Task.await(receiver, :infinity)
            Task.await(sender, :infinity)
    
            {:error, reason} ->
            IO.puts("Erreur de connexion : #{inspect(reason)}")
            end
          end

  Code receive_loop 1ere partie:
  
      defp receive_loop(socket) do
        case :gen_tcp.recv(socket, 0) do
          {:ok, msg} ->
            IO.write(msg)
            receive_loop(socket)
    
          {:error, _} ->
            IO.puts("Déconnecté")
        end
      end
