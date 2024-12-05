defmodule GettextLLM.Translator.Specs do
  @moduledoc """
  This module provides various translation specs.
  """

  @type opts() :: %{
          source_message: String.t(),
          source_language_code: String.t(),
          target_language_code: String.t()
        }
end
