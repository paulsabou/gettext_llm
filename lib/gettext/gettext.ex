defmodule GettextLLM.Gettext do
  @moduledoc """
  Gettext files related functions.
  """

  @lc_messages "LC_MESSAGES"

  @spec scan_root_folder(Path.t()) ::
          {
            :ok,
            list(%{
              language_code: String.t(),
              files: list(Path.t())
            })
          }
          | {:error, any()}
  def scan_root_folder(gettext_root_path) do
    with {:ok, files} <- File.ls(gettext_root_path),
         language_dirs <- Enum.filter(files, &File.dir?(Path.join(gettext_root_path, &1))) do
      language_files =
        Enum.map(language_dirs, fn langauge_dir ->
          {:ok, po_file_paths} =
            list_po_files_from_language_folder(Path.join([gettext_root_path, langauge_dir]))

          %{
            language_code: langauge_dir,
            files: po_file_paths
          }
        end)

      {:ok, language_files}
    end
  end

  @spec list_po_files_from_language_folder(Path.t()) :: {:ok, list(Path.t())} | {:error, any()}
  defp list_po_files_from_language_folder(language_folder_path) do
    with language_dir <- Path.join([language_folder_path, @lc_messages]),
         {:ok, files} <- File.ls(language_dir),
         po_files <-
           Enum.filter(files, &(!File.dir?(&1) && String.ends_with?(&1, ".po"))) do
      {:ok, Enum.map(po_files, &Path.join([language_folder_path, @lc_messages, &1]))}
    end
  end
end
