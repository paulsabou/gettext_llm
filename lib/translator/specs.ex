defmodule GettextLLM.Translator.Specs do
  @moduledoc """
  Various translation specs for the translators.
  """

  @type endpoint() :: %{
          adapter: module(),
          model: String.t(),
          temperature: float(),
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
