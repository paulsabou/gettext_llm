# Security Policy

  ## Supported Versions

  | Version | Supported          |
  | ------- | ------------------ |
  | 0.2.x   | :white_check_mark: |
  | < 0.2   | :x:                |

  ## Reporting a Vulnerability

  **Please do not report security vulnerabilities through public GitHub issues.**

  To report a vulnerability, email **paul.sabou@gmail.com** with the subject line `[SECURITY] gettext_llm`.

  Include:
  - Description of the vulnerability
  - Steps to reproduce
  - Potential impact
  - Any suggested fix (optional)

  ### Response Timeline

  - **Acknowledgement:** within 48 hours
  - **Status update:** within 7 days
  - **Fix or mitigation:** within 30 days for critical issues

  You will be credited in the release notes unless you prefer to remain anonymous.

  ## Scope

  **In scope:**
  - Prompt injection or LLM input/output handling vulnerabilities
  - Dependency vulnerabilities with direct exploitability
  - Authentication or API key exposure bugs

  **Out of scope:**
  - Vulnerabilities in underlying LLM providers (OpenAI, Anthropic, etc.) — report those upstream
  - Issues requiring physical access to the machine
  - Social engineering

  ## Preferred Language

  English.
