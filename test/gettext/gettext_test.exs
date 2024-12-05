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
end
