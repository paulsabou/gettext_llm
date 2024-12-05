defmodule GettextLLM.Translator.Specs do
  @moduledoc """
  This module provides various translation specs.
  """

  @type endpoint() :: %{
          adapter: module(),
          model: String.t(),
          config: map()
        }

  @type config() :: %{
          endpoint: endpoint(),
          persona: String.t(),
          style: String.t()
        }

  @type opts() :: %{
          source_message: String.t(),
          target_language_code: String.t()
        }
end
