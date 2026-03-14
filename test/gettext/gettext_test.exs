defmodule GettextLLM.GettextTest do
  @moduledoc """
  Documentation for `GettextLLM`.
  """

  use ExUnit.Case
  alias GettextLLM.Gettext.GettextHelper
  @samples_folder_path "test/gettext/sample2"

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

  describe "scan_root_folder/1" do
    test "scans the sample folder" do
      {:ok, results} = GettextLLM.Gettext.scan_root_folder(@samples_folder_path)

      %{
        files: [
          "test/gettext/sample2/en/LC_MESSAGES/default.po",
          "test/gettext/sample2/en/LC_MESSAGES/errors.po"
        ]
      } = Enum.find(results, &(&1.language_code == "en"))

      %{
        files: [
          "test/gettext/sample2/fr/LC_MESSAGES/default.po",
          "test/gettext/sample2/fr/LC_MESSAGES/errors.po"
        ]
      } = Enum.find(results, &(&1.language_code == "fr"))
    end
  end

  describe "extract_variables_from_string/1" do
    test "extracts variables from a string" do
      string = "singular - should be at most %{count} byte(s) and at least %{min} byte(s)"
      variables = GettextLLM.Gettext.variables_from_string(string)
      assert variables == ["count", "min"]
    end
  end

  describe "validate/2" do
    test "validates the sample folder" do
      {:error, results} =
        GettextLLM.validate(GettextLLM.get_config(), "priv/gettext_invalid_variables")

      assert length(results) == 2

      assert Enum.sort_by(results, & &1.file) == [
               %{
                 file: "priv/gettext_invalid_variables/fr/LC_MESSAGES/default.po",
                 errors: [
                   "Message `Actions %{year} %{month}` has variables that are not present in the translated message `Actions %{an} %{month} - fr`",
                   "Message `close %{year} %{month}` has variables that are not present in the translated message `close %{an} %{mois} - fr`"
                 ]
               },
               %{
                 file: "priv/gettext_invalid_variables/fr/LC_MESSAGES/errors.po",
                 errors: [
                   "Message `must be a valid email address %{year} %{month}` has variables that are not present in the translated message `must be a valid email address %{year} %{mois} - fr`",
                   "Plural message (singular form) `should have %{year} item(s)` has variables that are not present in the translated message `should have %{an} item(s) - fr`"
                 ]
               }
             ]
    end
  end
end
