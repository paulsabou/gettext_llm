defmodule GettextLLM.GettextLLMTest do
  @moduledoc """
  Documentation for `GettextLLM`.
  """

  use ExUnit.Case
  alias GettextLLM.Gettext.GettextHelper
  @samples_folder_path "test/gettext/sample3"

  setup do
    {:ok, _} =
      GettextHelper.setup_folder(%{
        samples_folder_path: @samples_folder_path,
        language_dirs: [
          %{
            language_code: "en",
            files: [
              %{
                name: "default",
                content: ~s"""
                #, elixir-autogen, elixir-format
                msgid "Actions"
                msgstr ""

                #, elixir-autogen, elixir-format
                msgid "close"
                msgstr ""
                """
              },
              %{
                name: "errors",
                content: """
                #, elixir-autogen, elixir-format
                msgid "invalid location"
                msgstr ""

                #, elixir-autogen, elixir-format
                msgid "must be a valid email address"
                msgstr ""

                #, elixir-autogen, elixir-format
                msgid "singular - should be at most %{count} byte(s)"
                msgid_plural "plural - should be at most %{count} byte(s)"
                msgstr[0] ""
                msgstr[1] ""
                """
              }
            ]
          },
          %{
            language_code: "fr",
            files: [
              %{
                name: "default",
                content: ~s"""
                #, elixir-autogen, elixir-format
                msgid "Actions"
                msgstr ""

                #, elixir-autogen, elixir-format
                msgid "close"
                msgstr ""
                """
              },
              %{
                name: "errors",
                content: """
                #, elixir-autogen, elixir-format
                msgid "invalid location"
                msgstr ""

                #, elixir-autogen, elixir-format
                msgid "must be a valid email address"
                msgstr ""

                #, elixir-autogen, elixir-format
                msgid "singular - should be at most %{count} byte(s)"
                msgid_plural "plural - should be at most %{count} byte(s)"
                msgstr[0] ""
                msgstr[1] ""

                #, elixir-autogen, elixir-format
                msgid "invalid name"
                msgstr "invalid name already translated"
                """
              }
            ]
          }
        ]
      })

    on_exit(fn ->
      # Cleanup
      GettextHelper.cleanup_folder(@samples_folder_path)
    end)

    :ok
  end

  describe "translate/3" do
    test "translates the sample folder" do
      {:ok, _} =
        GettextLLM.translate(
          GettextLLM.Translator.TranslatorTest,
          %{ignored_languages: []},
          @samples_folder_path
        )

      {:ok,
       ~s"""
       #, elixir-autogen, elixir-format
       msgid "Actions"
       msgstr "Actions - fr"

       #, elixir-autogen, elixir-format
       msgid "close"
       msgstr "close - fr"
       """} =
        GettextHelper.read_translation_file(@samples_folder_path, "fr", "default")

      {:ok,
       """
       #, elixir-autogen, elixir-format
       msgid "invalid location"
       msgstr "invalid location - fr"

       #, elixir-autogen, elixir-format
       msgid "must be a valid email address"
       msgstr "must be a valid email address - fr"

       #, elixir-autogen, elixir-format
       msgid "singular - should be at most %{count} byte(s)"
       msgid_plural "plural - should be at most %{count} byte(s)"
       msgstr[0] "singular - should be at most %{count} byte(s) - fr"
       msgstr[1] "plural - should be at most %{count} byte(s) - fr"

       #, elixir-autogen, elixir-format
       msgid "invalid name"
       msgstr "invalid name already translated"
       """} =
        GettextHelper.read_translation_file(@samples_folder_path, "fr", "errors")
    end
  end
end
