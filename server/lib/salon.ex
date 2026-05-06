defmodule MiniDiscord.Salon do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name, clients: [], historique: []},
      name: via(name))
  end

  def rejoindre(salon, pid), do: GenServer.call(via(salon), {:rejoindre, pid})
  def quitter(salon, pid),   do: GenServer.call(via(salon), {:quitter, pid})
  def broadcast(salon, msg), do: GenServer.cast(via(salon), {:broadcast, msg})
  def lister do
    Registry.select(MiniDiscord.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def init(state), do: {:ok, state}

  def handle_call({:rejoindre, pid}, _from, state) do
    # TODO : Monitorer le pid avec Process.monitor/1
    # TODO : Retourner {:reply, :ok, nouvel_état} avec pid ajouté à state.clients
    state =
      if Enum.member?(state.clients, pid) do
        state
      else
        Process.monitor(pid)
        Enum.each(state.historique, fn msg -> send(pid, {:message, msg}) end)
        %{state | clients: [pid | state.clients]}
      end

    {:reply, :ok, state}
  end

  def handle_call({:quitter, pid}, _from, state) do
    # TODO : Retourner {:reply, :ok, nouvel_état} avec pid retiré de state.clients
    new_clients = Enum.reject(state.clients, &(&1 == pid))
    {:reply, :ok, %{state | clients: new_clients}}
  end

  def handle_cast({:broadcast, msg}, state) do
    # TODO : Envoyer {:message, msg} à chaque pid dans state.clients
    # TODO : Retourner {:noreply, state}
    historique = Enum.take(state.historique ++ [msg], -10)
    Enum.each(state.clients, fn pid -> send(pid, {:message, msg}) end)
    {:noreply, %{state | historique: historique}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # TODO : Retirer pid de state.clients (il s'est déconnecté)
    # TODO : Retourner {:noreply, nouvel_état}
    new_clients = Enum.reject(state.clients, &(&1 == pid))
    {:noreply, %{state | clients: new_clients}}
  end

  defp via(name), do: {:via, Registry, {MiniDiscord.Registry, name}}
end
