defmodule Frequency do
  @moduledoc false

  ## Client
  def allocate, do: call(:allocate)
  def deallocate(frequency), do: call({:deallocate, frequency})
  def stop, do: call(:stop)

  defp call(message) do
    send(__MODULE__, {:request, self(), message})
    receive do
      {:reply, reply} ->
        reply
    end
  end

  ## Server

  @doc """
  Starts the Frequency server process. Also registers the process
  using the current module's name as alias

  Example:

    iex> Frequency.start
    iex> Frequency in Process.registered()
    true
  """
  def start do
    Process.register(spawn(__MODULE__, :init, []), __MODULE__)
  end

  @doc """
  Calling this directly results in a suspended receive
  """
  def init do
    frequencies = {get_frequencies(), []}
    loop(frequencies)
  end

  defp get_frequencies do
    [10, 11, 12, 13, 14, 15]
  end

  defp loop(frequencies) do
    receive do
      {:request, pid, :allocate} ->
        {new_frequencies, reply} = allocate(frequencies, pid)
        reply(pid, reply)
        loop(new_frequencies)

      {:request, pid, {:deallocate, frequency}} ->
        {new_frequencies, reply} = deallocate(frequencies, frequency)
        reply(pid, :ok)
        loop(new_frequencies)

      {:request, pid, :stop} ->
        reply(pid, :ok)
    end
  end

  def reply(pid, reply) do
    send(pid, {:reply, reply})
  end

  @doc """
  Returns a pre-allocated frequency, returns an error if all frequencies are taken
  """
  def allocate({[], allocated}, pid), do: {{[], allocated}, {:error, :no_frequency}}
  def allocate({[frequency | free], allocated}, pid) do
    {{free, [{frequency, pid} | allocated]}, {:ok, frequency}}
  end
  def deallocate({free, allocated}, frequency) do
    new_allocated =
      allocated
      |> Enum.reduce([], fn({freq, _pid} = f, acc) ->
        case freq == frequency do
          true ->
            acc
          false ->
            [f | acc]
        end
      end)
    {[frequency | free], new_allocated}
  end
end
