# AstrBot API Rules

These are high-confidence facts confirmed from the local AstrBot checkout at `c:\astrbot\AstrBot`.

Use these as evidence anchors before reporting framework-specific issues.

## Confirmed exports

### `logger`

- Local source: `astrbot/api/__init__.py`
- Confirmed export: `from astrbot import logger`
- Review implication: plugin code should use `from astrbot.api import logger` when following the public API surface

### `Context`, `Star`, `StarTools`, `register`

- Local source: `astrbot/api/star/__init__.py`
- Confirmed export: `from astrbot.core.star import Context, Star, StarTools`
- Confirmed public registration alias: `register`

### `AstrMessageEvent`

- Local source: `astrbot/api/event/__init__.py`
- Confirmed export: `AstrMessageEvent`

### `filter`

- Local source: `astrbot/api/event/filter/__init__.py`
- Confirmed public decorators include:
  - `command`
  - `command_group`
  - `permission_type`
  - `on_astrbot_loaded`
  - `on_llm_request`
  - `on_llm_response`
  - `on_decorating_result`
  - `after_message_sent`
  - `llm_tool`
  - `on_using_llm_tool`
  - `on_llm_tool_respond`

### Provider request/response types

- Local source: `astrbot/api/provider/__init__.py`
- Confirmed exports:
  - `ProviderRequest`
  - `LLMResponse`

## Confirmed behavior

### `StarTools.get_data_dir()`

- Local source: `astrbot/core/star/star_tools.py`
- Confirmed return type: `Path`
- Confirmed behavior: creates and returns `data/plugin_data/{plugin_name}`
- Review implication: code that treats the result as a plain string should be reviewed carefully

### `@filter.on_llm_request()`

- Local source: `astrbot/core/star/register/star_handler.py`
- Docs example: `docs/zh/dev/star/plugin.md`
- Confirmed expectation: plugin method receives `self, event, request`
- Review implication: missing `event` or request parameter is a strong candidate issue

### `@filter.on_llm_response()`

- Local source: `astrbot/core/star/register/star_handler.py`
- Docs example: `docs/zh/dev/star/plugin.md`
- Confirmed expectation: plugin method receives `self, event, response`

### Event hook mixing

- Local docs: `docs/zh/dev/star/plugin.md`
- Confirmed doc guidance: event hooks should not be combined with `command`, `command_group`, `event_message_type`, `platform_adapter_type`, or `permission_type`
- Review implication: treat this as a strong rule because it is explicit product documentation adjacent to the hook model

### `@filter.llm_tool`

- Local source: `astrbot/core/star/register/star_handler.py`
- Confirmed behavior:
  - parses the decorated function docstring
  - requires parameter type annotations in docstring form
  - rejects unsupported parameter types
- Review implication: missing docstring metadata or unsupported types are confirmed issues

## Guardrails

- Do not use `astrabot.api`; the local framework namespace is `astrbot.api`
- Do not invent framework rules that are not present in local source or docs
- Do not escalate a pure code-style preference into a framework violation
