defmodule GettextLLM.Translator.Translator do
  @moduledoc """
  Translator behavior. Any translators must implement this.
  """
  alias GettextLLM.Translator.Specs
  @callback translate(Specs.config(), Specs.opts()) :: {:ok, String.t()} | {:error, any()}
end
