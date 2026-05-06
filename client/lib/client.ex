defmodule MiniDiscord.Client do

  @doc """
  Point d'entrée principal du client.
  host : nom type 'xxxbore.pub'
  port : entier ex: 4040
  """
  def start(host, port) do
    connect_with_retry(host, port, 1)
  end

  defp connect_with_retry(host, port, attempt) do
    case :gen_tcp.connect(String.to_charlist(host), port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        IO.puts("Connecté au serveur #{host}:#{port}")

        handshake(socket)

        receiver = Task.async(fn -> receive_loop(socket) end)
        sender = Task.async(fn -> send_loop(socket) end)

        Task.await(receiver, :infinity)
        Task.await(sender, :infinity)

      {:error, reason} ->
        IO.puts("Tentative #{attempt} échouée : #{inspect(reason)}")
        :timer.sleep(2000)
        connect_with_retry(host, port, attempt + 1)
    end
  end
  

  defp rencontre(socket) do
    # Message de bienvenue
    recv_print(socket)

    # Envoi pseudo
    pseudo = IO.gets("Pseudo : ")
    :gen_tcp.send(socket, pseudo)

    # Liste des salons
    recv_print(socket)

    # Choix salon
    salon = IO.gets("Salon : ")
    :gen_tcp.send(socket, salon)

    # Confirmation
    recv_print(socket)
  end

  defp receive_loop(socket, host, port) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} ->
        IO.write(msg)
        receive_loop(socket, host, port)

      {:error, reason} ->
        IO.puts("\nConnexion perdue (#{inspect(reason)}). Reconnexion...")

        :gen_tcp.close(socket)

        connect_with_retry(host, port, 1)
    end
  end

  defp send_loop(socket) do
    case IO.gets("") do
      nil ->
        :gen_tcp.close(socket)

      msg ->
        :gen_tcp.send(socket, msg)
        send_loop(socket)
    end
  end

  defp recv_print(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} -> IO.write(msg)
      {:error, _} -> IO.puts("Erreur réception")
    end
  end

end