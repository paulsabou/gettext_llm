defmodule GettextLLM.Translator.TranslatorLangchain do
  @moduledoc """
  Translation functions based on langchain.
  """
  @behaviour GettextLLM.Translator.Translator

  alias GettextLLM.Translator.Specs
  alias LangChain.Message
  alias LangChain.Chains.LLMChain

  @spec translate(Specs.config(), Specs.opts()) :: {:ok, String.t()} | {:error, any()}
  def translate(config, opts) do
    completion(config, opts)
  end

  def translator_persona_default() do
    "You are translating messages for a website. You will provide translation that is casual but respectful and uses plain language."
  end

  def translator_style_default() do
    "Casual but respectul. Uses plain plain language that can be understood by all age groups and demographics."
  end

  @spec completion(Specs.config(), Specs.opts()) :: {:ok, String.t()} | {:error, any()}
  defp completion(config, opts) do
    set_langchain = fn ->
      Enum.each(Map.keys(config.endpoint.config), fn key ->
        :ok =
          Application.put_env(
            :langchain,
            String.to_atom(key),
            Map.get(config.endpoint.config, key)
          )
      end)

      :ok
    end

    with :ok <- set_langchain.(),
         {:ok, _updated_chain, response} <-
           LLMChain.new!(%{
             llm:
               config.endpoint.adapter.new!(%{
                 model: config.endpoint.model,
                 temperature: config.endpoint.temperature
               })
           })
           |> LLMChain.add_messages([
             Message.new_system!("#{config.persona}. Your translation style is #{config.style}"),
             Message.new_user!(
               "Translate the message between <|input_start|> and <|input_end|> into language with POSIX code '#{opts.target_language_code}'. Your answer mus contain only the message translation. The message to be translated is <|input_start|>#{opts.source_message}<|input_end|>"
             )
           ])
           |> LLMChain.run() do
      {:ok, response.content}
    end
  end
end
