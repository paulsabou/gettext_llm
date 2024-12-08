# Gettext LLM

## Automated translations

Translating text in from one language to another requires the translator to be accurate and to maintain a consistent tone/persona and style. 
Scaling these to multiple languages is challenging. Automated translation with LLM's provide a "good enough" alternative in many use cases.

**Elixir Gettext LLM** library allows you to translate all Gettext PO folders/files in your project using any LLM endpoint supported by `langchain`. 
The library provides several mix tasks that can be run directly in your Elixir/Phoenix project from the command line (ie. locally on the dev machine) or part of a CI/CD pipeline.

`gettext_llm` provides configurable tone/persona and style. This allows you to "shape" your resulting translations into something that is compatible with your app audience & brand.

## Installation

The package can be installed by adding `gettext_llm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gettext_llm, "~> 0.1.6", only: [:dev, :test], runtime: false}
  ]
end
```

## Usage

### 1. Use `gettext` to extract & merge
`gettext_llm` translates PO files. Use `gettext` to extract all the translated messages from your app into POT files & merge them into their respective PO files
```
mix gettext.extract --merge
```

### 2. Add the `gettext_llm` in your `config.exs` 

`gettext_llm` uses [langchain](https://github.com/brainlid/langchain) to call the LLM endpoints. As such `gettext_llm` can translate using any LLM endpoint supported by `langchain`. `gettext_llm` reads the endpoint specific config and passes it directly to `langchain`.

#### Example configuration with OpenAI
```
# General application configuration
import Config

config :gettext_llm, GettextLLM,
  gettext_backend: MyApp.Gettext <--- Optional
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
  gettext_backend: MyApp.Gettext  <--- Optional
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

### 3. Run `gettext_llm` mix task

#### Run using the default gettext location (ie. priv/gettext)
```
mix gettext_llm.translate translate
```

#### Run using a specific gettext location
```
mix gettext_llm.translate translate my_path/gettext 
```


### Other `gettext_llm` mix task

#### Check that your configuration is correct
```
mix gettext_llm.translate info
```

#### Display help
```
mix help gettext_llm.translate 
```

## Documentation
Documentation can be be found at <https://hexdocs.pm/gettext_llm>.

## Misc
For some apps or languages LLM's are not good enough. In these cases you will probably be better off with a human translator. The human translator could work on it's own or part of a hybrind setup. A typical setup has the draft translation version proposed by an LLM and the final approval (and corrections) are performed by the human. Good open source solutions for such a setup are [Kanta](https://github.com/curiosum-dev/kanta) or [Weblate](https://github.com/WeblateOrg/weblate).

## Thanks
Special thanks to [Adrian Codausi](https://github.com/AdrianCDS) & [Goran Codausi](https://github.com/goran-cds) for inspiring me to build this.
They have build an earlier prototype of a similar functionality in another project.