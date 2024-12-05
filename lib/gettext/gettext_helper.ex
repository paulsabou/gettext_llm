defmodule GettextLLM.Gettext.GettextHelper do
  @moduledoc """
  Test helper
  """

  @lc_messages "LC_MESSAGES"

  @spec setup_folder(%{
          samples_folder_path: String.t(),
          language_dirs:
            list(%{
              language_code: String.t(),
              files:
                list(%{
                  name: String.t(),
                  content: binary()
                })
            })
        }) :: {:ok, non_neg_integer()} | {:error, any()}
  def setup_folder(opts) do
    # Create root
    :ok = File.mkdir(opts.samples_folder_path)

    # Create language dirs
    Enum.each(opts.language_dirs, fn language_dir ->
      :ok = File.mkdir(Path.join([opts.samples_folder_path, language_dir.language_code]))

      :ok =
        File.mkdir(
          Path.join([opts.samples_folder_path, language_dir.language_code, @lc_messages])
        )

      Enum.each(language_dir.files, fn file ->
        :ok =
          File.write(
            Path.join([
              opts.samples_folder_path,
              language_dir.language_code,
              @lc_messages,
              "#{file.name}.po"
            ]),
            file.content
          )
      end)
    end)

    {:ok, Enum.count(opts.language_dirs)}
  end

  def cleanup_folder(folder_path) do
    _ = File.rm_rf(folder_path)
  end

  @spec read_translation_file(String.t(), String.t(), String.t()) ::
          {:ok, binary()} | {:error, any()}
  def read_translation_file(samples_folder_path, language_code, domain) do
    File.read(Path.join([samples_folder_path, language_code, @lc_messages, "#{domain}.po"]))
  end
end
