---
name: review-astrbot-plugin
description: Review an AstrBot plugin against the local AstrBot implementation in c:\astrbot\AstrBot. Use this when auditing plugin code, validating hook signatures, checking astrbot.api imports, or replacing prompt-only AI review rules with evidence from local source and docs.
metadata:
  short-description: Review AstrBot plugins using local source-of-truth.
---

# Review AstrBot Plugin

Review AstrBot plugins against the local AstrBot implementation in `c:\astrbot\AstrBot`.

Use this skill when:

- the user asks to review an AstrBot plugin
- a previous review prompt is unreliable, outdated, or not tied to real AstrBot behavior
- you need to confirm `astrbot.api` imports, hook signatures, `llm_tool` requirements, or `StarTools` behavior from local source

Default source-of-truth policy:

- Prefer local source under `c:\astrbot\AstrBot\astrbot`
- Use local docs under `c:\astrbot\AstrBot\docs` only to clarify intent or examples
- If source and docs disagree, trust source and call out the mismatch

## Workflow

1. Identify the plugin root.
   Default targets:
   - `main.py`
   - `metadata.yaml`
   - all `*.py` files

2. Extract plugin surface facts first.
   Run `scripts/extract_plugin_surface.ps1` against the plugin directory.

3. For every suspected issue, find AstrBot evidence before judging.
   Run `scripts/find_astrbot_rule.ps1` with a symbol, decorator, or rule phrase.

4. Classify findings conservatively.
   - `Confirmed issue`: directly supported by local source, exported API, or a hard requirement documented beside the implementation
   - `Likely risk`: docs or examples recommend a pattern, but local implementation does not prove it is mandatory
   - `Needs manual confirmation`: behavior depends on runtime context, dynamic registration, third-party libraries, or code not available locally

5. Do not turn style opinions into hard errors.
   Only report framework-specific issues when there is local evidence.

## Review Rules

Load [references/astrbot-api-rules.md](references/astrbot-api-rules.md) for confirmed AstrBot facts.

Load [references/astrbot-review-checklist.md](references/astrbot-review-checklist.md) for the review checklist and anti-false-positive rules.

High-confidence checks for this skill:

- `from astrbot.api import logger`
- `StarTools.get_data_dir()` returns a `Path`
- hook signatures around `@filter.on_llm_request()` and `@filter.on_llm_response()`
- hook decorators should not be mixed with message filters like `command` or `permission_type`
- `@filter.llm_tool` requires a parseable docstring and supported type annotations

## Script Usage

Use the scripts from this skill directory.

Extract plugin structure:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\extract_plugin_surface.ps1 -PluginPath C:\astrbot\some-plugin
```

Find AstrBot evidence:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\find_astrbot_rule.ps1 -Query "on_llm_request"
```

Optional flags:

- `extract_plugin_surface.ps1 -AsText`
- `find_astrbot_rule.ps1 -MaxResults 20`
- `find_astrbot_rule.ps1 -SourceRoot C:\astrbot\AstrBot`

## Output Format

Use this structure:

```markdown
Conclusion: 1-3 sentences.

Findings

1. [Severity] Title
   Plugin evidence: path:line
   AstrBot basis: path:line
   Why this matters: concise explanation
   Suggested fix: concrete change

Residual risks

- Manual-only concerns that could not be proven from local source
```

Rules for output:

- Sort findings by severity, then confidence
- Include both plugin evidence and AstrBot basis for every non-empty finding
- If there are no confirmed issues, say so explicitly
- Keep `Likely risk` and `Needs manual confirmation` separate from confirmed failures
- Do not use the old `astrabot` typo from prompt-only review systems
- Do not tell the user a dependency is "outdated" unless the issue is directly relevant to the local implementation being reviewed

## Failure Handling

If `c:\astrbot\AstrBot` is missing or unreadable:

- stop and say the local AstrBot source-of-truth is unavailable
- do not silently fall back to generic Python review rules
- do not claim framework constraints you cannot prove
