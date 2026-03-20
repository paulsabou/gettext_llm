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

    prompt_skip_translation_of_variables =
      if !Enum.empty?(opts.source_message_variables) do
        "The message is a string template with variables between %{} like %{variable_name}. The message has the following variables: #{Enum.join(opts.source_message_variables, ", ")}. Do not translate the variables, only the text outside the variables."
      else
        ""
      end

    with :ok <- set_langchain.(),
         {:ok, response} <-
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
               "Translate the message between <|input_start|> and <|input_end|> into language with POSIX code '#{opts.target_language_code}'.
                Your answer mus contain only the message translation.
                #{prompt_skip_translation_of_variables}
                The message to be translated is <|input_start|>#{opts.source_message}<|input_end|>"
             )
           ])
           |> LLMChain.run() do
      {:ok, extract_translation(response)}
    end
  end

  defp extract_translation(response) do
    [content_part | _] = response.last_message.content
    content_part.content
  end
end
