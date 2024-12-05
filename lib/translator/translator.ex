defmodule GettextLLM.Translator.Translator do
  @moduledoc """
  This module provides a translator behavior.
  """
  alias GettextLLM.Translator.Specs
  @callback translate(Specs.opts()) :: {:ok, String.t()} | {:error, any()}
end
