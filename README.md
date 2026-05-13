#1ere Partie

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

#Partie 2

-> Lors du redémarrage du serveur les clients ne peuvent pas se reconnecter mais le serveur lui reste opérationnel et les données telles que les salons et les messages (les 10 derniers) sont conservées.

-> Après modifications les tests montrent tests on voit que le serveur n'est pas relancé, la reconnexion est donc impossible.

2.3 -> la supervision OTP relance automatiquement les processus crashés et isole les pannes. Grâce aux Tasks le code fait tout manuellement et peut rester dans un état cassé si une boucle meurt.

2.4 -> Filtrage des messages mis en place et les tests sotn fonctionnels

2.5 -> Après implémentation le cryptage des messages semble effectif.
