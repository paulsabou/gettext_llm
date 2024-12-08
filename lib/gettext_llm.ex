defmodule GettextLLM do
  @moduledoc """
  Gettext LLM main functions.
  """

  require Logger
  alias Expo.Message
  alias GettextLLM.Translator.Specs
  alias GettextLLM.Translator.TranslatorLangchain

  @spec get_config() :: Specs.config()
  def get_config() do
    config = Application.fetch_env!(:gettext_llm, __MODULE__)

    default_locale =
      if Keyword.has_key?(config, :gettext_backend) do
        gettext_backend = Keyword.fetch!(config, :gettext_backend)
        Gettext.get_locale(gettext_backend)
      else
        Gettext.get_locale()
      end

    %{
      endpoint: %{
        adapter: Keyword.fetch!(config, :endpoint),
        model: Keyword.fetch!(config, :endpoint_model),
        temperature: Keyword.fetch!(config, :endpoint_temperature),
        config: Keyword.fetch!(config, :endpoint_config)
      },
      persona: Keyword.get(config, :persona, TranslatorLangchain.translator_persona_default()),
      style: Keyword.get(config, :style, TranslatorLangchain.translator_style_default()),
      ignored_languages: [default_locale]
    }
  end

  @spec translate(module(), Specs.config(), Path.t()) ::
          {:ok, non_neg_integer()} | {:error, any()}
  def translate(module, config, root_gettext_path) do
    {:ok, results} = GettextLLM.Gettext.scan_root_folder(root_gettext_path)

    translate_po_folder = fn po_folder ->
      if po_folder.language_code in config.ignored_languages do
        Logger.info(
          "Folder `#{po_folder.language_code}` appears in ignored languages [#{Enum.join(config.ignored_languages, ", ")}] - SKIPPING"
        )

        0
      else
        Logger.info("Folder `#{po_folder.language_code}` - starting processing ")

        po_folder.files
        |> Enum.map(&translate_one_po_file(module, config, po_folder.language_code, &1))
        |> Enum.map(fn {_status, count} -> count end)
        |> Enum.sum()
      end
    end

    {:ok,
     results
     |> Enum.map(&translate_po_folder.(&1))
     |> Enum.sum()}
  end

  @spec translate_one_po_file(module(), Specs.config(), String.t(), Path.t()) ::
          {:ok, non_neg_integer()} | {:error, any()}
  defp translate_one_po_file(module, config, po_language_code, po_file_path) do
    translate_messages = fn po_file ->
      translated_message_count =
        Enum.count(po_file.messages, &empty_message_translation?(&1))

      Logger.info(
        "File `#{po_file_path}` has #{translated_message_count} entries that need to be translated to `#{po_language_code}`"
      )

      if(translated_message_count > 0,
        do:
          {translated_message_count,
           Enum.map(
             po_file.messages,
             &translate_one_message(module, config, po_language_code, &1)
           )},
        else: {0, po_file.messages}
      )
    end

    with {:ok, po_file} <- Expo.PO.parse_file(po_file_path),
         {translated_message_count, po_messages} <-
           translate_messages.(po_file),
         updated_po_file = %{
           po_file
           | messages: po_messages
         },
         :ok <- File.write(po_file_path, Expo.PO.compose(updated_po_file)) do
      {:ok, translated_message_count}
    end
  end

  @spec translate_one_message(module(), Specs.config(), String.t(), Message.t()) :: Message.t()
  defp translate_one_message(module, config, po_language_code, message) do
    case message do
      %Message.Singular{:msgstr => msgstr, :msgid => [value_to_translate]}
      when msgstr == [""] ->
        Logger.info("* Translating message `#{value_to_translate}` to `#{po_language_code}` ")

        {:ok, translated_value} =
          module.translate(config, %{
            source_message: value_to_translate,
            target_language_code: po_language_code
          })

        %{
          message
          | msgstr: [translated_value]
        }

      %Message.Plural{
        :msgstr => %{0 => [translated_value1], 1 => [translated_value2]},
        :msgid => [value_to_translate_singular],
        :msgid_plural => [value_to_translate_plural]
      } ->
        if empty_string?(translated_value1) || empty_string?(translated_value2) do
          Logger.info(
            "* Translating plural message `#{value_to_translate_singular}` / `#{value_to_translate_plural}` to `#{po_language_code}` "
          )

          {:ok, translated_value_singular} =
            module.translate(config, %{
              source_message: value_to_translate_singular,
              target_language_code: po_language_code
            })

          {:ok, translated_value_plural} =
            module.translate(config, %{
              source_message: value_to_translate_plural,
              target_language_code: po_language_code
            })

          %{
            message
            | msgstr: %{0 => [translated_value_singular], 1 => [translated_value_plural]}
          }
        else
          message
        end

      %{:msgid => [value_to_translate]} ->
        Logger.info(
          "* Translating message `#{value_to_translate}` to `#{po_language_code}` - SKIPPED "
        )

        message
    end
  end

  @spec empty_string?(String.t()) :: boolean()
  defp empty_string?(string_value) do
    if is_nil(string_value) do
      true
    else
      String.trim(string_value) == ""
    end
  end

  defp empty_message_translation?(message) do
    case message do
      %Message.Singular{:msgstr => [value]} ->
        empty_string?(value)

      %Message.Plural{:msgstr => %{0 => [value1], 1 => [value2]}} ->
        empty_string?(value1) || empty_string?(value2)
    end
  end
end
