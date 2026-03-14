defmodule GettextLLM do
  @moduledoc File.read!(Path.expand("./README.md"))

  require Logger
  alias Expo.Message
  alias GettextLLM.Translator.Specs
  alias GettextLLM.Translator.TranslatorLangchain

  @doc """
  Loads the `gettext_llm` configuration from the app configuration.
  """
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
      style: Keyword.get(config, :style, TranslatorLangchain.translator_style_default()),
      ignored_languages: Keyword.get(config, :ignored_languages, [])
    }
  end

  @doc """
  Validates all the PO files inside the language folders using a specific
  configuration and LLM endpoint.
  """
  @spec validate(Specs.config(), Path.t()) ::
          {:ok, true} | {:error, list(%{file: Path.t(), errors: list(String.t())})}
  def validate(config, root_gettext_path) do
    validate_po_folder = fn po_folder ->
      if po_folder.language_code in config.ignored_languages do
        Logger.info(
          "Folder `#{po_folder.language_code}` appears in ignored languages [#{Enum.join(config.ignored_languages, ", ")}] - SKIPPING"
        )

        {:ok, true}
      else
        Logger.info("Folder `#{po_folder.language_code}` - starting validation ")

        files_validation_results =
          Enum.map(po_folder.files, fn file ->
            case validate_translation_one_po_file(file) do
              {:ok, true} ->
                {:ok, file}

              {:error, errors} ->
                {:error, %{file: file, errors: errors}}
            end
          end)

        if Enum.all?(files_validation_results, fn {status, _} -> status == :ok end) do
          {:ok, true}
        else
          # Collect all the errors
          errors =
            files_validation_results
            |> Enum.filter(fn {status, _} -> status == :error end)
            |> Enum.map(fn {_status, %{file: file, errors: errors}} ->
              %{file: file, errors: errors}
            end)

          {:error, errors}
        end
      end
    end

    {:ok, results} = GettextLLM.Gettext.scan_root_folder(root_gettext_path)

    errors =
      results
      |> Enum.map(&validate_po_folder.(&1))
      |> Enum.filter(fn {status, _} -> status == :error end)
      |> Enum.flat_map(fn {:error, payload} -> List.wrap(payload) end)

    if length(errors) > 0 do
      {:error, errors}
    else
      {:ok, true}
    end
  end

  @doc """
  Translates all the PO files inside the language folders using a specific
  cnfiguration and LLM endpoint.
  """
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

  @spec validate_translation_one_po_file(Path.t()) ::
          {:ok, true} | {:error, list(String.t())}
  defp validate_translation_one_po_file(po_file_path) do
    validate_messages = fn po_file ->
      invalid_messages =
        po_file.messages
        |> Enum.filter(fn message -> !empty_message_translation?(message) end)
        |> Enum.map(&validate_one_message(&1))
        |> Enum.filter(fn {status, _} -> status == :error end)
        |> Enum.map(fn {_status, message} -> message end)

      if length(invalid_messages) > 0 do
        {:error, invalid_messages}
      else
        {:ok, po_file}
      end
    end

    with {:ok, po_file} <- Expo.PO.parse_file(po_file_path),
         {:ok, _} <- validate_messages.(po_file) do
      {:ok, true}
    end
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
    handle_singular_message = fn message ->
      %Message.Singular{:msgstr => msgstr, :msgid => value_to_translate} = message

      if empty_string?(to_str(msgstr)) do
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
      else
        message
      end
    end

    handle_plural_message = fn
      message ->
        %Message.Plural{
          :msgstr => %{0 => multi_translated_value1, 1 => multi_translated_value2},
          :msgid => [value_to_translate_singular],
          :msgid_plural => [value_to_translate_plural]
        } = message

        translated_value1 = to_str(multi_translated_value1)
        translated_value2 = to_str(multi_translated_value2)

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
    end

    case message do
      %Message.Singular{} ->
        handle_singular_message.(message)

      %Message.Plural{} ->
        handle_plural_message.(message)
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
      %Message.Singular{:msgstr => value} ->
        empty_string?(to_str(value))

      %Message.Plural{:msgstr => %{0 => value1, 1 => value2}} ->
        empty_string?(to_str(value1)) || empty_string?(to_str(value2))
    end
  end

  defp to_str(value) do
    Enum.join(value, " ")
  end

  @spec validate_one_message(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  defp validate_one_message(%Message.Singular{} = message) do
    %Message.Singular{:msgstr => msgstr, :msgid => msgid} = message

    original_message_variables = GettextLLM.Gettext.variables_from_string(to_str(msgid))
    translated_message_variables = GettextLLM.Gettext.variables_from_string(to_str(msgstr))

    if original_message_variables != translated_message_variables do
      {:error,
       "Message `#{to_str(msgid)}` has variables that are not present in the translated message `#{to_str(msgstr)}`"}
    else
      {:ok, message}
    end
  end

  defp validate_one_message(%Message.Plural{} = message) do
    %Message.Plural{
      msgid: msgid,
      msgid_plural: msgid_plural,
      msgstr: msgstr
    } = message

    singular_source_vars = GettextLLM.Gettext.variables_from_string(to_str(msgid))
    plural_source_vars = GettextLLM.Gettext.variables_from_string(to_str(msgid_plural))

    msgstr
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.reduce_while(:ok, fn
      {0, translated}, _acc ->
        translated_vars = GettextLLM.Gettext.variables_from_string(to_str(translated))

        if singular_source_vars != translated_vars do
          {:halt,
           {:error,
            "Plural message (singular form) `#{to_str(msgid)}` has variables that are not present in the translated message `#{to_str(translated)}`"}}
        else
          {:cont, :ok}
        end

      {_idx, translated}, _acc ->
        translated_vars = GettextLLM.Gettext.variables_from_string(to_str(translated))

        if plural_source_vars != translated_vars do
          {:halt,
           {:error,
            "Plural message (plural form) `#{to_str(msgid_plural)}` has variables that are not present in the translated message `#{to_str(translated)}`"}}
        else
          {:cont, :ok}
        end
    end)
    |> case do
      :ok -> {:ok, message}
      {:error, reason} -> {:error, reason}
    end
  end
end
