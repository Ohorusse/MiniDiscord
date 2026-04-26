defmodule MinidiscordTest do
  use ExUnit.Case
  doctest Minidiscord

  test "greets the world" do
    assert Minidiscord.hello() == :world
  end
end
