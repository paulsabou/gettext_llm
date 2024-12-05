defmodule GettextLLM.Translator.TranslatorTest do
  @moduledoc """
  This module provides various translation functions.
  """
  @behaviour GettextLLM.Translator.Translator

  alias GettextLLM.Translator.Specs

  @spec translate(Specs.config(), Specs.opts()) :: {:ok, String.t()} | {:error, any()}
  def translate(_config, opts) do
    {:ok, "#{opts.source_message} - #{opts.target_language_code}"}
  end
end
