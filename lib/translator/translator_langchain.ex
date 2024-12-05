defmodule GettextLLM.Translator.TranslatorLangchain do
  @moduledoc """
  This module provides various translation functions.
  """
  @behaviour GettextLLM.Translator.Translator

  alias GettextLLM.Translator.Specs

  @spec translate(Specs.opts()) :: {:ok, String.t()} | {:error, any()}
  def translate(opts) do
    {:ok,
     if opts.source_language_code == opts.target_language_code do
       opts.source_message
     else
       "#{opts.source_message} - #{opts.target_language_code}"
     end}
  end
end
