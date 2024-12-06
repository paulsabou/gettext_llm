defmodule GettextLLM do
  @moduledoc """
  Gettext LLM main functions.
  """

  alias GettextLLM.Translator.Specs
  alias GettextLLM.Translator.TranslatorLangchain

  @spec empty_string?(String.t()) :: boolean()
  defp empty_string?(string_value) do
    if is_nil(string_value) do
      true
    else
      String.trim(string_value) == ""
    end
  end

  defp empty_message_translation?(message) do
    [value] = message.msgstr
    empty_string?(value)
  end

  @spec get_config() :: Specs.config()
  def get_config() do
    config = Application.fetch_env!(:gettext_llm, __MODULE__)

    %{
      endpoint: %{
        adapter: Keyword.fetch!(config, :endpoint),
        model: Keyword.fetch!(config, :endpoint_model),
        temperature: Keyword.fetch!(config, :endpoint_temperature),
        config: Keyword.fetch!(config, :endpoint_config)
      },
      persona: Keyword.get(config, :persona, TranslatorLangchain.translator_persona_default()),
      style: Keyword.get(config, :style, TranslatorLangchain.translator_style_default())
    }
  end

  @spec translate(module(), Specs.config(), Path.t()) ::
          {:ok, non_neg_integer()} | {:error, any()}
  def translate(module, config, root_gettext_path) do
    {:ok, results} = GettextLLM.Gettext.scan_root_folder(root_gettext_path)

    translate_po_folder = fn po_folder ->
      po_folder.files
      |> Enum.map(&translate_one_po_file(module, config, po_folder.language_code, &1))
      |> Enum.map(fn {_status, count} -> count end)
      |> Enum.sum()
    end

    {:ok,
     results
     |> Enum.map(&translate_po_folder.(&1))
     |> Enum.sum()}
  end

  @spec translate_one_po_file(module(), Specs.config(), String.t(), Path.t()) ::
          {:ok, non_neg_integer()} | {:error, any()}
  defp translate_one_po_file(module, config, po_language_code, po_file_path) do
    translate_message = fn message ->
      if empty_message_translation?(message) do
        [value] = message.msgid

        {:ok, translated_msgstr} =
          module.translate(config, %{
            source_message: value,
            target_language_code: po_language_code
          })

        %{message | msgstr: [translated_msgstr]}
      else
        message
      end
    end

    with {:ok, po_file} <- Expo.PO.parse_file(po_file_path),
         po_messages <- Enum.map(po_file.messages, &translate_message.(&1)),
         translated_message_count =
           Enum.count(po_messages, &empty_message_translation?(&1)),
         updated_po_file = %{
           po_file
           | messages: po_messages
         },
         :ok <- File.write(po_file_path, Expo.PO.compose(updated_po_file)) do
      {:ok, translated_message_count}
    end
  end
end
