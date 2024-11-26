defmodule GettextLLMTest do
  use ExUnit.Case
  doctest GettextLLM

  test "greets the world" do
    assert GettextLLM.hello() == :world
  end
end
