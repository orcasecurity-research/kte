from ai.config import LLM_MODELS, CONFIG
from openai import AsyncOpenAI

OPENAI_DEFAULTS = {
    "model": LLM_MODELS["GPT_4o_MINI"],
    "response_format": {"type": "text"},
    "temperature": 0
}

client = AsyncOpenAI(
    api_key=CONFIG["OPENAI_API_KEY"],
)


async def open_ai_completion(payload: list[dict[str, str]]):
    chat_completion = await client.chat.completions.create(
        **OPENAI_DEFAULTS,
        messages=payload
    )

    return chat_completion.choices[0].message.content
