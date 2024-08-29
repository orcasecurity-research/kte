import os
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

load_dotenv()

os.environ["TOKENIZERS_PARALLELISM"] = "false"
embedder = SentenceTransformer("all-MiniLM-L6-v2", tokenizer_kwargs={'clean_up_tokenization_spaces': False})

LLM_MODELS: dict[str, str] = {
    "GPT_4o_MINI": "gpt-4o-mini"
}

CONFIG = {
    "OPENAI_API_KEY": os.environ["OPENAI_API_KEY"],
}
