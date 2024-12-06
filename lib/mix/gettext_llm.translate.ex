defmodule Mix.Tasks.GettextLlm.Translate do
  @moduledoc ~s"""
   GettextLLM usage:
   * Translate using default gettext folder (priv/gettext)
      ```
      mix gettext_llm.translate translate
      ```

   * Translate using specific gettext folder
      ```
      mix gettext_llm.translate translate my_path/gettext
      ```

   * Display info (including current configuration)
      ```
      mix gettext_llm.translate info
      ```

   * Display help
      ```
      mix help gettext_llm.translate
      ```
  """
  @shortdoc "Translates Gettext PO folder(s) using an LLM endpoint."

  @requirements ["app.start"]
  @preferred_cli_env :dev

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    gettext_root_dir = Enum.at(args, 1, "priv/gettext")

    config = GettextLLM.get_config()

    case Enum.at(args, 0, "info") do
      "info" ->
        display_info(gettext_root_dir, config)

      "translate" ->
        Mix.shell().info("GettextLLM translation started")

        {:ok, translated_message_count} =
          GettextLLM.translate(
            GettextLLM.Translator.TranslatorLangchain,
            config,
            Path.join([gettext_root_dir])
          )

        Mix.shell().info(
          "GettextLLM translation finished. #{translated_message_count} messages translated"
        )
    end
  end

  defp display_info(gettext_root_dir, config) do
    Mix.shell().info(~s"""
    * OK: Translator GettextLLM configuration loaded
      * LLM: #{config.endpoint.adapter}
      * Model: #{config.endpoint.model}
      * Temperature: #{config.endpoint.temperature}
      * Config: ### redacted ###
      * Persona: #{config.persona}
      * Style: #{config.style}
    """)

    if File.exists?(gettext_root_dir) do
      {:ok, translation_candidates} = GettextLLM.Gettext.scan_root_folder(gettext_root_dir)

      Mix.shell().info(~s"""
      * OK: Gettext translation folder
        * Root dir: #{gettext_root_dir}
        * #{Enum.count(translation_candidates)} Languages detected: #{Enum.map_join(translation_candidates, ", ", & &1.language_code)}
      """)
    else
      Mix.shell().info(~s"""
      * ERROR: Gettext translation folder #{gettext_root_dir} is missing
      """)
    end
  end
end
