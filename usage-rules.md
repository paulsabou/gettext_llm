# Rules for working with Gettext LLM

## Gettext LLM
gettext_llm is an opinionated library for translating gettext files during the development process.
It provides a mix based task interface and is intented to be used by developpers as part of their
development process or CI/CD.

## Installation

The package can be installed by adding `gettext_llm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
      {:gettext_llm, "0.2.0", only: [:dev, :test]}
  ]
end
```

The gettext_llm package should only be installed in dev & test environments. It should not be used in production as gettext translation files are generated at compile time for most projects.

See the package [installation guide documentation](https://hexdocs.pm/gettext_llm/GettextLLM.html#module-installation) for more details.

## Usage

### 1. Use `gettext` to extract & merge
`gettext_llm` translates PO files. Use `gettext` to extract all the translated messages from your app into POT files & merge them into their respective PO files
```
mix gettext.extract
mix gettext.merge priv/gettext --no-fuzzy
```

### 2. Add the `gettext_llm` in your `config.exs` 

`gettext_llm` uses [langchain](https://github.com/brainlid/langchain) to call the LLM endpoints. As such `gettext_llm` can translate using any LLM endpoint supported by `langchain`. `gettext_llm` reads the endpoint specific config and passes it directly to `langchain`.

#### Example configuration with OpenAI
```
# General application configuration
import Config

config :gettext_llm, GettextLLM,
  # ignored_languages: ["en"] <--- Optional but good to skip translating your reference language 
  persona:
    "You are translating messages for a website that connects people needing help with people that can provide help. You will provide translation that is casual but respectful and uses plain language.",
  style:
    "Casual but respectul. Uses plain plain language that can be understood by all age groups and demographics.",
  endpoint: LangChain.ChatModels.ChatOpenAI,
  endpoint_model: "gpt-4",
  endpoint_temperature: 0,
  endpoint_config: %{
    "openai_key" =>
      "<YOUR_OPENAI_KEY>",
    "openai_org_id" => "<YOUR_ORG_ID>"
  }
```

#### Example configuration with Anthropic
```
# General application configuration
import Config

config :gettext_llm, GettextLLM,
  # ignored_languages: ["en"] <--- Optional but good to skip translating your reference language 
  persona:
    "You are translating messages for a website that connects people needing help with people that can provide help. You will provide translation that is casual but respectful and uses plain language.",
  style:
    "Casual but respectul. Uses plain plain language that can be understood by all age groups and demographics.",
  endpoint: LangChain.ChatModels.ChatAnthropic,
  endpoint_model: "claude-3-5-sonnet-latest",
  endpoint_temperature: 0,
  endpoint_config: %{
    "anthropic_key" =>
      "<YOUR_ANTHROPIC_KEY>"
  }
```

See the package [installation usage documentation](https://hexdocs.pm/gettext_llm/GettextLLM.html#module-usage) for more details.


### 3. Run `gettext_llm` mix task

#### Run using the default gettext location (ie. priv/gettext)
```
mix gettext_llm.translate translate
```

#### Run using a specific gettext location
```
mix gettext_llm.translate translate my_path/gettext 
```
