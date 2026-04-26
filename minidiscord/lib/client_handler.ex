defmodule MiniDiscord.ClientHandler do
  require Logger

  def start(socket) do
    :gen_tcp.send(socket, "Bienvenue sur MiniDiscord!\r\n")
    pseudo = choisir_pseudo(socket)

    :gen_tcp.send(socket, "Salons disponibles : #{salons_dispo()}\r\n")
    :gen_tcp.send(socket, "Rejoins un salon (ex: general) : ")
    {:ok, salon} = :gen_tcp.recv(socket, 0)
    salon = String.trim(salon)

    entrer_salon(socket, pseudo, salon)
    loop(socket, pseudo, salon)
  end

  defp entrer_salon(socket, pseudo, salon) do
    case Registry.lookup(MiniDiscord.Registry, salon) do
      [] ->
        DynamicSupervisor.start_child(
          MiniDiscord.SalonSupervisor,
          {MiniDiscord.Salon, salon})
      _ -> :ok
    end

    MiniDiscord.Salon.rejoindre(salon, self())
    MiniDiscord.Salon.broadcast(salon, "📢 #{pseudo} a rejoint ##{salon}\r\n")
    :gen_tcp.send(socket, "Tu es dans ##{salon} — écris tes messages !\r\n")
  end

  defp choisir_pseudo(socket) do
    :gen_tcp.send(socket, "Entre ton pseudo : ")

    case :gen_tcp.recv(socket, 0) do
      {:ok, pseudo} ->
        pseudo = String.trim(pseudo)

        if pseudo_disponible?(pseudo) do
          reserver_pseudo(pseudo)
          pseudo
        else
          :gen_tcp.send(socket, "Pseudo déjà pris, choisis-en un autre.\r\n")
          choisir_pseudo(socket)
        end

      {:error, reason} ->
        exit(reason)
    end
  end

  defp loop(socket, pseudo, salon) do
    receive do
      {:message, msg} ->
        :gen_tcp.send(socket, msg)
    after 0 -> :ok
    end

    case :gen_tcp.recv(socket, 0, 100) do
      {:ok, msg} ->
        msg = String.trim(msg)
        if String.starts_with?(msg, "/") do
          case gerer_commande(socket, pseudo, salon, msg) do
            {:ok, nouveau_salon} -> loop(socket, pseudo, nouveau_salon)
            :quit -> :ok
          end
        else
          MiniDiscord.Salon.broadcast(salon, "[#{pseudo}] #{msg}\r\n")
          loop(socket, pseudo, salon)
        end

      {:error, :timeout} ->
        loop(socket, pseudo, salon)

      {:error, reason} ->
        Logger.info("Client déconnecté : #{inspect(reason)}")
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
        liberer_pseudo(pseudo)
    end
  end

  defp gerer_commande(socket, pseudo, salon, commande) do
    case String.split(commande, " ", parts: 2) do
      ["/list"] ->
        :gen_tcp.send(socket, "Salons actifs : #{salons_dispo()}\r\n")
        {:ok, salon}

      ["/join", nouveau_salon] ->
        nouveau_salon = String.trim(nouveau_salon)

        if nouveau_salon == "" do
          :gen_tcp.send(socket, "Usage : /join <nom>\r\n")
          {:ok, salon}
        else
          MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
          MiniDiscord.Salon.quitter(salon, self())
          entrer_salon(socket, pseudo, nouveau_salon)
          {:ok, nouveau_salon}
        end

      ["/quit"] ->
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
        liberer_pseudo(pseudo)
        :gen_tcp.close(socket)
        :quit

      _ ->
        :gen_tcp.send(socket, "Commande inconnue\r\n")
        {:ok, salon}
    end
  end

  defp pseudo_disponible?(pseudo) do
    case :ets.lookup(:pseudos, pseudo) do
      [] -> true
      _ -> false
    end
  end

  defp reserver_pseudo(pseudo) do
    :ets.insert(:pseudos, {pseudo, self()})
  end

  defp liberer_pseudo(pseudo) do
    :ets.delete(:pseudos, pseudo)
  end

  defp salons_dispo do
    case MiniDiscord.Salon.lister() do
      [] -> "aucun (tu seras le premier !)"
      salons -> Enum.join(salons, ", ")
    end
  end
end
