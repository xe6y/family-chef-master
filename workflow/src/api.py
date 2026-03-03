#!/usr/bin/env python3
"""
菜谱提取 API 服务

对外暴露 HTTP 接口，供 Flutter App 调用 recipe_extractor 模块。

用法：
  uvicorn api:app --host 0.0.0.0 --port 8100 --reload
"""

import os
import sys
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from dotenv import load_dotenv

# 确保同目录下的 recipe_extractor 可被导入
sys.path.insert(0, os.path.dirname(__file__))
from recipe_extractor import extract_recipe

load_dotenv()

app = FastAPI(title="Cookmate Recipe Extractor API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ExtractRequest(BaseModel):
    url: str
    provider: str = "openai"
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

    - provider: openai / anthropic / kimi（默认 openai）
    - model: 模型名称（不传则使用各 provider 默认模型）
    - resolve_ids: 是否调用 Cookmate API 解析食材 ID（默认 true）
    """
    default_models = {
        "openai": "gpt-4o",
        "anthropic": "claude-3-5-sonnet-20241022",
        "kimi": "moonshot-v1-32k",
    }
    model_name = req.model or default_models.get(req.provider, "gpt-4o")

    key_map = {
        "openai": "OPENAI_API_KEY",
        "anthropic": "ANTHROPIC_API_KEY",
        "kimi": "MOONSHOT_API_KEY",
    }
    key_env = key_map.get(req.provider, "OPENAI_API_KEY")
    if not os.environ.get(key_env):
        raise HTTPException(
            status_code=500,
            detail=f"服务端未配置 {key_env}，无法使用 {req.provider} 提供商",
        )

    try:
        recipe = extract_recipe(
            url=req.url,
            provider=req.provider,
            model_name=model_name,
            resolve_ids=req.resolve_ids,
        )
        return ExtractResponse(success=True, data=recipe)
    except ValueError as e:
        return ExtractResponse(success=False, error=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
