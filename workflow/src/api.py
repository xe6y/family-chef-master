#!/usr/bin/env python3
"""
菜谱提取 API 服务

对外暴露 HTTP 接口，供 Flutter App 调用 recipe_extractor 模块。

用法：
  uvicorn api:app --host 0.0.0.0 --port 8100 --reload
"""

import logging
import os
import sys
import traceback
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from dotenv import load_dotenv

# 先加载环境变量，再导入 recipe_extractor（它也依赖环境变量）
_ENV_PATH = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_ENV_PATH)

sys.path.insert(0, os.path.dirname(__file__))
from recipe_extractor import extract_recipe

app = FastAPI(title="Cookmate Recipe Extractor API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


_KEY_MAP = {
    "openai": "OPENAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "kimi": "MOONSHOT_API_KEY",
}

_DEFAULT_MODELS = {
    "openai": "gpt-5.2",
    "anthropic": "claude-sonnet-4-6",
    "kimi": "kimi-k2.5",
}


def _auto_provider() -> str:
    """每次调用时动态检测可用 provider。
    优先级：MOONSHOT_API_KEY > ANTHROPIC_API_KEY > OPENAI_API_KEY
    """
    if os.environ.get("MOONSHOT_API_KEY"):
        return "kimi"
    if os.environ.get("ANTHROPIC_API_KEY"):
        return "anthropic"
    return "openai"


class ExtractRequest(BaseModel):
    url: str
    # None 表示"自动检测"，handler 中按环境变量优先级决定
    provider: Optional[str] = None
    model: Optional[str] = None
    resolve_ids: bool = True


class ExtractResponse(BaseModel):
    success: bool
    data: Optional[dict] = None
    error: Optional[str] = None


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/extract", response_model=ExtractResponse)
def extract(req: ExtractRequest):
    """
    从 URL 提取菜谱结构。

    - provider: openai / anthropic / kimi（不传则按环境变量自动选择）
    - model: 模型名称（不传则使用各 provider 默认模型）
    - resolve_ids: 是否调用 Cookmate API 解析食材 ID（默认 true）
    """
    # 每次请求时动态确定 provider，避免模块加载时环境变量未就绪
    provider = req.provider or _auto_provider()
    model_name = req.model or _DEFAULT_MODELS.get(provider, "gpt-5.2")

    key_env = _KEY_MAP.get(provider, "OPENAI_API_KEY")
    if not os.environ.get(key_env):
        raise HTTPException(
            status_code=500,
            detail=f"服务端未配置 {key_env}，无法使用 {provider} 提供商",
        )

    try:
        recipe = extract_recipe(
            url=req.url,
            provider=provider,
            model_name=model_name,
            resolve_ids=req.resolve_ids,
        )
        return ExtractResponse(success=True, data=recipe)
    except ValueError as e:
        return ExtractResponse(success=False, error=str(e))
    except Exception as e:
        logging.error("extract_recipe failed:\n%s", traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))
