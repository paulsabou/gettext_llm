defmodule GettextLLM.Translator.TranslatorLangchain do
  @moduledoc """
  This module provides various translation functions based on langchain.
  """
  @behaviour GettextLLM.Translator.Translator

  alias GettextLLM.Translator.Specs
  alias LangChain.Message
  alias LangChain.Chains.LLMChain

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
             llm: config.endpoint.adapter.new!(%{model: config.endpoint.model})
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

  @spec translate(Specs.config(), Specs.opts()) :: {:ok, String.t()} | {:error, any()}
  def translate(config, opts) do
    completion(config, opts)
  end
end
