# AstrBot Review Checklist

Use this checklist after extracting plugin surface facts.

## Strong rules

Report as `Confirmed issue` only when backed by local AstrBot evidence.

### Public API imports

- Wrong namespace such as `astrabot.api`
- Suspicious logger import when a plugin is expected to use `from astrbot.api import logger`
- Missing public API import for `AstrMessageEvent`, `Star`, `StarTools`, or provider types when the code claims to rely on them

### Hook signatures

Check:

- `@filter.on_llm_request()` methods accept `self, event, request`
- `@filter.on_llm_response()` methods accept `self, event, response`
- hook methods are `async def`

### Hook decorator mixing

Flag event hooks combined with message-filter decorators such as:

- `@filter.command`
- `@filter.command_group`
- `@filter.event_message_type`
- `@filter.platform_adapter_type`
- `@filter.permission_type`

### `StarTools.get_data_dir()`

Check:

- return value handled like a `Path`
- plugin does not build a duplicate `data/plugin_data/...` path around the returned value

### `@filter.llm_tool`

Check:

- docstring exists
- docstring parameters have supported type names
- function signature still includes `event`

## Weak rules

Report as `Likely risk` unless local source makes them strict.

- plugin entry structure looks unusual compared with local docs
- event handler signature is unconventional but still plausibly supported
- message-sending style inside hooks may be questionable but is not proven incorrect from local source
- synchronous network I/O candidates appear inside async paths

## Needs manual confirmation

Use this when you cannot prove runtime behavior from static reading.

- dynamic decorator wrapping
- reflection-based registration
- third-party helper layers hiding actual network calls
- plugin architecture spread across generated files or imports you cannot inspect

## Anti-false-positive rules

- Do not cite the old prompt typo `astrabot`
- Do not claim a rule purely because it existed in another AI review prompt
- Do not flag a library as old or deprecated unless the local AstrBot implementation itself depends on that distinction
- Do not report generic Python style issues as framework violations
- If source is silent and docs are only suggestive, downgrade the result out of `Confirmed issue`
