defmodule GettextLLM do
  @moduledoc """
  Gettext LLM related functions.
  """

  @spec empty_string?(String.t()) :: boolean()
  def empty_string?(string_value) do
    if is_nil(string_value) do
      true
    else
      String.trim(string_value) == ""
    end
  end

  def empty_message_translation?(message) do
    [value] = message.msgstr
    empty_string?(value)
  end

  @spec translate(module(), String.t(), Path.t()) ::
          {:ok, non_neg_integer()} | {:error, any()}
  def translate(module, pot_language_code, root_gettext_path) do
    {:ok, results} = GettextLLM.Gettext.scan_root_folder(root_gettext_path)

    translate_po_folder = fn po_folder ->
      po_folder.files
      |> Enum.map(&translate_one_po_file(module, pot_language_code, po_folder.language_code, &1))
      |> Enum.map(fn {_status, count} -> count end)
      |> Enum.sum()
    end

    {:ok,
     results
     |> Enum.map(&translate_po_folder.(&1))
     |> Enum.sum()}
  end

  @spec translate_one_po_file(module(), String.t(), String.t(), Path.t()) ::
          {:ok, non_neg_integer()} | {:error, any()}
  defp translate_one_po_file(module, pot_language_code, po_language_code, po_file_path) do
    translate_message = fn message ->
      if empty_message_translation?(message) do
        [value] = message.msgid

        {:ok, translated_msgstr} =
          module.translate(%{
            source_message: value,
            source_language_code: pot_language_code,
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
