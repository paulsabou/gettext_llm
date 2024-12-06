defmodule GettextLLM.Translator.TranslatorLangchainTest do
  @moduledoc """
  Langchain tests
  """
  use ExUnit.Case

  describe "translate/2" do
    test "Langchain based translator translates correctly" do
      {:ok, translation} =
        GettextLLM.Translator.TranslatorLangchain.translate(
          GettextLLM.get_config(),
          %{
            source_message:
              "Describe the persona of translator to improve the accuracy of the translation",
            target_language_code: "fr"
          }
        )

      assert translation ==
               "Décrivez la personnalité du traducteur pour améliorer la précision de la traduction"
    end
  end
end
