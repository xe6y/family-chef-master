#!/usr/bin/env python3
"""
菜谱提取器 - 将视频链接或图文教程链接转换为 Cookmate 菜谱格式

支持：
  - YouTube 视频（自动加载字幕）
  - Bilibili 视频（加载页面描述）
  - 任意图文教程网页

流程：
  1. 加载 URL 内容（字幕 / 网页抓取）
  2. 用 LLM 提取结构化菜谱
  3. 调用 Cookmate API 将食材名 / 单位名解析为数据库 ID
  4. 输出符合 PublicRecipe 格式的 JSON

用法：
  export OPENAI_API_KEY=sk-...
  export COOKMATE_EMAIL=user@example.com
  export COOKMATE_PASSWORD=yourpassword
  python recipe_extractor.py <URL>
  python recipe_extractor.py <URL> --output recipe.json
  python recipe_extractor.py <URL> --provider anthropic --no-resolve
  python recipe_extractor.py <URL> --provider kimi --model moonshot-v1-32k
"""

import json
import os
import sys
from typing import Optional
from urllib.parse import urlparse

import requests
from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field

load_dotenv()

# ============================================================
# Pydantic 数据模型（LLM 输出用）
# ============================================================

class RecipeIngredientRaw(BaseModel):
    """LLM 提取的食材（原始文字，未解析 ID）"""

    ingredientName: str = Field(description="食材名称，如'猪五花肉'、'生姜'")
    quantity: Optional[float] = Field(
        default=None,
        description="数量，适量/少许等不确定数量时为 null",
    )
    unitName: str = Field(
        default="适量",
        description="单位名称，如'克'、'毫升'、'个'、'片'、'勺'、'适量'",
    )


class IngredientConversion(BaseModel):
    """LLM 估算的单位换算信息（以克为基准）"""

    ingredientName: str = Field(description="食材标准名称，如'胡萝卜'")
    unitName: str = Field(description="单位名称，如'根'、'片'、'个'")
    unitType: str = Field(
        description=(
            "单位类型，必须是以下之一：weight（重量，如克/千克）/ "
            "volume（体积，如毫升/杯）/ count（计数，如根/个/片）/ unspecified"
        )
    )
    gramsPerUnit: float = Field(
        description="1 个该单位对应多少克（g）的估算值，必须大于 0。"
        "例：1 根胡萝卜 ≈ 80g，则填 80.0"
    )


class ConversionList(BaseModel):
    """LLM 批量估算结果"""

    items: list[IngredientConversion]


class RecipeExtracted(BaseModel):
    """LLM 提取的菜谱（与 PublicRecipe 结构对齐）"""

    name: str = Field(description="菜谱名称")
    image: str = Field(default="", description="菜谱封面图 URL，无法获取则为空字符串")
    time: str = Field(description="制作总时间，如'20分钟'、'1小时30分钟'")
    difficulty: str = Field(
        description=(
            "难度等级，必须从以下五个选项中选一个："
            "有手就行 / 家常便饭 / 餐厅招牌 / 硬核挑战 / 专业厨师"
        )
    )
    tags: list[str] = Field(
        default_factory=list,
        description="标签列表，如['家常菜','快手菜','下饭菜']，3~5个",
    )
    categories: list[str] = Field(
        default_factory=list,
        description="分类列表，如['中餐','炒菜']，1~3个",
    )
    ingredients: list[RecipeIngredientRaw] = Field(description="食材列表")
    steps: list[str] = Field(
        description="制作步骤列表，每步是一句完整的操作说明，不含序号前缀"
    )


# ============================================================
# Cookmate API 客户端 - 食材 ID 解析
# ============================================================

class CookmateClient:
    """
    调用 Cookmate 后端 API，将食材名 / 单位名批量解析为数据库 ID。

    使用 POST /api/ingredient-master/resolve 接口，一次请求完成所有解析，
    匹配逻辑在服务端执行（精确 → ILIKE → 全局单位回退）。

    认证优先级：
      1. COOKMATE_TOKEN 环境变量（直接使用 JWT）
      2. COOKMATE_EMAIL + COOKMATE_PASSWORD（自动登录获取 JWT）
    """

    def __init__(self, base_url: str, token: Optional[str] = None):
        self.base_url = base_url.rstrip("/")
        self.token = token

    @classmethod
    def from_env(cls) -> Optional["CookmateClient"]:
        """从环境变量创建客户端，未配置时返回 None"""
        base_url = os.environ.get("COOKMATE_API_URL", "http://localhost:8080/api")

        token = os.environ.get("COOKMATE_TOKEN")
        if token:
            print("[+] 使用 COOKMATE_TOKEN 认证", file=sys.stderr)
            return cls(base_url, token=token)

        email = os.environ.get("COOKMATE_EMAIL")
        password = os.environ.get("COOKMATE_PASSWORD")
        if email and password:
            client = cls(base_url)
            client.login(email, password)
            return client

        return None

    def login(self, email: str, password: str) -> None:
        """登录并获取 JWT Token"""
        resp = requests.post(
            f"{self.base_url}/auth/login",
            json={"email": email, "password": password},
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()
        self.token = (
            data.get("data", {}).get("token")
            or data.get("token")
        )
        if not self.token:
            raise ValueError(f"登录响应中未找到 token：{data}")
        print("[+] Cookmate 登录成功", file=sys.stderr)

    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self.token}"}

    def ensure_batch(self, conversions: list["IngredientConversion"]) -> list[dict]:
        """
        批量确保食材和单位存在，不存在则自动创建。

        调用 POST /api/ingredient-master/ensure，服务端执行：
          1. find-or-create ingredient_master
          2. find-or-create units（按 display_name）
          3. find-or-create ingredient_unit（写入 factorToBase）

        Returns:
            EnsuredResult 列表，字段：ingredientId, ingredientName, unitId, unitName, created[]
        """
        payload = {
            "items": [
                {
                    "ingredientName": conv.ingredientName,
                    "unitName": conv.unitName,
                    "unitType": conv.unitType,
                    "factorToBase": conv.gramsPerUnit,
                }
                for conv in conversions
            ]
        }
        resp = requests.post(
            f"{self.base_url}/ingredient-master/ensure",
            json=payload,
            headers=self._headers(),
            timeout=30,
        )
        resp.raise_for_status()
        ensured = resp.json().get("data", {}).get("ensured", [])

        for e in ensured:
            created = e.get("created", [])
            tag = "[新建]" if created else "[已存在]"
            detail = f"({', '.join(created)})" if created else ""
            print(
                f"  {tag} {e['ingredientName']} / {e['unitName']} "
                f"(ingredientId={e['ingredientId']}, unitId={e['unitId']}) {detail}",
                file=sys.stderr,
            )

        return ensured

    def resolve_batch(
        self, ingredients: list["RecipeIngredientRaw"]
    ) -> list[dict]:
        """
        批量解析食材名 + 单位名为数据库 ID。

        调用 POST /api/ingredient-master/resolve，服务端完成：
          - 精确匹配食材名 → ILIKE 模糊匹配
          - 食材专属单位精确/模糊匹配 → 全局单位回退

        Returns:
            ResolvedIngredientResult 列表，字段：
              ingredientId, ingredientName, unitId, unitName, matched
        """
        payload = {
            "ingredients": [
                {"name": ing.ingredientName, "unit": ing.unitName}
                for ing in ingredients
            ]
        }
        resp = requests.post(
            f"{self.base_url}/ingredient-master/resolve",
            json=payload,
            headers=self._headers(),
            timeout=30,
        )
        resp.raise_for_status()
        resolved = resp.json().get("data", {}).get("resolved", [])

        for r in resolved:
            status = "[+]" if r.get("matched") else "[!]"
            ing_info = f"'{r['inputName']}' → '{r.get('ingredientName', '?')}' (id={r.get('ingredientId', '未找到')})"
            unit_info = f"'{r['inputUnit']}' → '{r.get('unitName', '?')}' (unitId={r.get('unitId', '未找到')})"
            print(f"  {status} 食材 {ing_info}  |  单位 {unit_info}", file=sys.stderr)

        return resolved


# ============================================================
# 内容加载
# ============================================================

def _is_youtube(url: str) -> bool:
    hostname = urlparse(url).hostname or ""
    return hostname in ("www.youtube.com", "youtube.com", "youtu.be", "m.youtube.com")


def _is_bilibili(url: str) -> bool:
    hostname = urlparse(url).hostname or ""
    return "bilibili.com" in hostname


def _load_youtube(url: str) -> str:
    """加载 YouTube 字幕，失败时回退到网页抓取"""
    try:
        from langchain_community.document_loaders import YoutubeLoader

        loader = YoutubeLoader.from_youtube_url(
            url,
            add_video_info=True,
            language=["zh-Hans", "zh-Hant", "zh", "en"],
        )
        docs = loader.load()
        if docs:
            print("[+] YouTube 字幕加载成功", file=sys.stderr)
            return "\n\n".join(doc.page_content for doc in docs)
    except Exception as e:
        print(f"[!] YouTube 字幕加载失败（{e}），回退到网页抓取", file=sys.stderr)

    return _load_webpage(url)


def _load_webpage(url: str) -> str:
    """通用网页内容加载"""
    from langchain_community.document_loaders import WebBaseLoader

    loader = WebBaseLoader(
        url,
        requests_kwargs={
            "headers": {"User-Agent": "Mozilla/5.0 (compatible; RecipeBot/1.0)"}
        },
    )
    docs = loader.load()
    return "\n\n".join(doc.page_content for doc in docs)


def load_content(url: str) -> str:
    """根据 URL 类型加载内容，返回纯文本"""
    if _is_youtube(url):
        print("[+] 检测到 YouTube 链接", file=sys.stderr)
        return _load_youtube(url)
    elif _is_bilibili(url):
        print("[+] 检测到 Bilibili 链接，加载页面内容", file=sys.stderr)
        return _load_webpage(url)
    else:
        print("[+] 检测到图文网页链接", file=sys.stderr)
        return _load_webpage(url)


# ============================================================
# LLM 提取（LangChain v0.3 with_structured_output）
# ============================================================

SYSTEM_PROMPT = """\
你是一个专业的菜谱提取助手。从用户提供的内容中提取完整的菜谱信息。

【难度等级说明】
- 有手就行：极简单，完全不需要厨艺
- 家常便饭：普通家常菜，基础操作即可
- 餐厅招牌：有一定技巧和火候要求
- 硬核挑战：需要较高厨艺或特殊工具
- 专业厨师：专业级，需要专业技能和设备

【提取规则】
1. 食材数量能精确识别的填数字，"适量"/"少许"等不确定的 quantity 用 null
2. 步骤要完整清晰，每步是一句完整操作说明，不要加"第一步："等前缀
3. 分类参考：中餐、西餐、日料、韩餐、烘焙、甜点、汤类、凉拌、炒菜、炖煮、蒸煮、烧烤、火锅
4. 标签参考：家常菜、快手菜、下饭菜、低卡、高蛋白、适合新手、宴客菜、儿童友好
5. 如内容中无菜谱，name 填"未识别"，其余字段为空
"""


def _make_llm(provider: str, model_name: str):
    """构建带结构化输出的 LLM（LangChain v0.3 with_structured_output）"""
    if provider == "anthropic":
        from langchain_anthropic import ChatAnthropic

        llm = ChatAnthropic(model=model_name, temperature=0, max_tokens=4096)
        return llm.with_structured_output(RecipeExtracted)
    elif provider == "kimi":
        from langchain_openai import ChatOpenAI

        llm = ChatOpenAI(
            model=model_name,
            temperature=0,
            openai_api_key=os.environ.get("MOONSHOT_API_KEY"),
            openai_api_base="https://api.moonshot.cn/v1",
        )
        return llm.with_structured_output(RecipeExtracted, method="json_schema")
    else:
        from langchain_openai import ChatOpenAI

        llm = ChatOpenAI(model=model_name, temperature=0)
        # method="json_schema" 使用 OpenAI 原生 JSON Schema，输出更稳定
        return llm.with_structured_output(RecipeExtracted, method="json_schema")


def _llm_extract(url: str, content: str, provider: str, model_name: str) -> RecipeExtracted:
    """调用 LLM 提取菜谱结构"""
    structured_llm = _make_llm(provider, model_name)
    prompt = ChatPromptTemplate.from_messages([
        ("system", SYSTEM_PROMPT),
        ("human", "来源 URL：{url}\n\n内容：\n{content}"),
    ])
    chain = prompt | structured_llm
    return chain.invoke({"url": url, "content": content})


CONVERSION_SYSTEM_PROMPT = """\
你是一个食材换算专家。对于给定的食材和单位组合，估算 1 个该单位对应多少克（g）。

规则：
1. 重量单位（克、千克、毫克等）直接换算：1克=1g，1千克=1000g
2. 体积单位按食材常见密度估算：1毫升液体≈1g，1杯≈240ml
3. 计数单位（根、个、片、块、条、颗等）按该食材的平均重量估算
4. 给出合理的中间估算值（不要给范围，取中间值）
5. unitType 说明：weight=重量单位，volume=体积单位，count=计数/个数单位，unspecified=其他
"""


def estimate_conversions(
    unmatched: list[tuple["RecipeIngredientRaw", dict]],
    provider: str,
    model_name: str,
) -> list[IngredientConversion]:
    """
    对 resolve 未匹配的食材，调用 LLM 批量估算单位换算比例（1单位=多少克）。

    Args:
        unmatched: [(RecipeIngredientRaw, resolve_result)] 列表，仅含 matched=false 的项
        provider:  LLM 提供商
        model_name: 模型名称

    Returns:
        IngredientConversion 列表，顺序与 unmatched 一致
    """
    if not unmatched:
        return []

    # 构建待估算列表描述
    lines = []
    for ing, resolved in unmatched:
        name = resolved.get("ingredientName") or ing.ingredientName
        unit = ing.unitName
        lines.append(f"- 食材：{name}，单位：{unit}")
    items_desc = "\n".join(lines)

    print(f"[+] LLM 估算 {len(unmatched)} 个未匹配食材的换算比例...", file=sys.stderr)

    if provider == "anthropic":
        from langchain_anthropic import ChatAnthropic
        llm = ChatAnthropic(model=model_name, temperature=0, max_tokens=2048)
    elif provider == "kimi":
        from langchain_openai import ChatOpenAI
        llm = ChatOpenAI(
            model=model_name,
            temperature=0,
            openai_api_key=os.environ.get("MOONSHOT_API_KEY"),
            openai_api_base="https://api.moonshot.cn/v1",
        )
    else:
        from langchain_openai import ChatOpenAI
        llm = ChatOpenAI(model=model_name, temperature=0)

    structured_llm = llm.with_structured_output(ConversionList)
    result: ConversionList = structured_llm.invoke(
        f"{CONVERSION_SYSTEM_PROMPT}\n\n请为以下食材+单位估算换算值：\n{items_desc}"
    )

    # 补齐数量（防止 LLM 漏项）
    conversions = result.items
    while len(conversions) < len(unmatched):
        ing, resolved = unmatched[len(conversions)]
        name = resolved.get("ingredientName") or ing.ingredientName
        conversions.append(
            IngredientConversion(
                ingredientName=name,
                unitName=ing.unitName,
                unitType="unspecified",
                gramsPerUnit=100.0,
            )
        )

    for conv in conversions:
        print(
            f"  [+] 换算估算：{conv.ingredientName} / {conv.unitName} "
            f"→ {conv.gramsPerUnit}g/unit（{conv.unitType}）",
            file=sys.stderr,
        )

    return conversions


# ============================================================
# 主流程
# ============================================================

def extract_recipe(
    url: str,
    provider: str = "openai",
    model_name: str = "gpt-4o",
    resolve_ids: bool = True,
) -> dict:
    """
    从 URL 提取菜谱并（可选）解析食材 ID。

    Args:
        url:         要解析的链接
        provider:    LLM 提供商，"openai" 或 "anthropic"
        model_name:  模型名称
        resolve_ids: 是否调用 Cookmate API 解析食材/单位 ID

    Returns:
        符合 PublicRecipe 结构的字典
    """
    # 1. 加载内容
    content = load_content(url)
    if not content.strip():
        raise ValueError("无法从该 URL 获取有效内容")

    MAX_CHARS = 12000
    if len(content) > MAX_CHARS:
        content = content[:MAX_CHARS]
        print(f"[!] 内容已截断至 {MAX_CHARS} 字符", file=sys.stderr)

    # 2. LLM 提取
    print(f"[+] 使用 {provider}/{model_name} 提取菜谱...", file=sys.stderr)
    extracted: RecipeExtracted = _llm_extract(url, content, provider, model_name)

    # 3. 尝试解析食材 ID
    client: Optional[CookmateClient] = None
    if resolve_ids:
        client = CookmateClient.from_env()
        if client is None:
            print(
                "[!] 未配置 Cookmate API 凭据，跳过 ID 解析。\n"
                "    请设置 COOKMATE_TOKEN 或 COOKMATE_EMAIL + COOKMATE_PASSWORD",
                file=sys.stderr,
            )

    ingredients_output = []
    if client and extracted.ingredients:
        # ---- Step A: 批量解析已有 ID ----
        print("[+] 开始批量解析食材 ID...", file=sys.stderr)
        resolved_list = client.resolve_batch(extracted.ingredients)

        # ---- Step B: 收集未匹配项，LLM 估算换算比例 ----
        unmatched_pairs: list[tuple[RecipeIngredientRaw, dict]] = [
            (ing, resolved)
            for ing, resolved in zip(extracted.ingredients, resolved_list)
            if not resolved.get("matched")
        ]

        # ensure_map: 以 (ingredientName_lower, unitName_lower) 为 key → EnsuredResult
        ensure_map: dict[tuple[str, str], dict] = {}
        if unmatched_pairs:
            conversions = estimate_conversions(unmatched_pairs, provider, model_name)

            # ---- Step C: 调用 ensure 接口创建缺失数据 ----
            print("[+] 调用 ensure 接口补充食材库数据...", file=sys.stderr)
            ensured_list = client.ensure_batch(conversions)
            for ensured in ensured_list:
                key = (
                    ensured["ingredientName"].lower(),
                    ensured["unitName"].lower(),
                )
                ensure_map[key] = ensured

        # ---- Step D: 合并 resolve + ensure 结果 ----
        for ing, resolved in zip(extracted.ingredients, resolved_list):
            if resolved.get("matched"):
                ingredients_output.append({
                    "ingredientId": resolved["ingredientId"],
                    "quantity": ing.quantity,
                    "unitId": resolved["unitId"],
                    "_ingredientName": resolved["ingredientName"],
                    "_unitName": resolved["unitName"],
                })
            else:
                # 在 ensure 结果中查找（用食材名和单位名联合匹配）
                ing_name = (resolved.get("ingredientName") or ing.ingredientName).lower()
                unit_name = ing.unitName.lower()
                ensured = ensure_map.get((ing_name, unit_name))

                if ensured and ensured.get("ingredientId") and ensured.get("unitId"):
                    ingredients_output.append({
                        "ingredientId": ensured["ingredientId"],
                        "quantity": ing.quantity,
                        "unitId": ensured["unitId"],
                        "_ingredientName": ensured["ingredientName"],
                        "_unitName": ensured["unitName"],
                        "_created": ensured.get("created", []),
                    })
                else:
                    # ensure 也失败，保留原始名称标记
                    ingredients_output.append({
                        "ingredientId": resolved.get("ingredientId", ""),
                        "quantity": ing.quantity,
                        "unitId": resolved.get("unitId", ""),
                        "_ingredientName": resolved.get("ingredientName") or ing.ingredientName,
                        "_unitName": ing.unitName,
                        "_unresolved": True,
                    })
    else:
        # 未连接 API：保留原始名称，标记待处理
        for ing in extracted.ingredients:
            ingredients_output.append({
                "ingredientId": "",
                "quantity": ing.quantity,
                "unitId": "",
                "_ingredientName": ing.ingredientName,
                "_unitName": ing.unitName,
                "_unresolved": True,
            })

    # 4. 组装最终输出（对齐 PublicRecipe 结构）
    output = {
        "name": extracted.name,
        "image": extracted.image or "",
        "time": extracted.time,
        "difficulty": extracted.difficulty,
        "tags": extracted.tags,
        "tagColors": [],       # 由应用层按标签填充颜色
        "categories": extracted.categories,
        "ingredients": ingredients_output,
        "steps": extracted.steps,
        "source": url,
        "creatorId": "",       # 导入时由调用方填充
    }

    return output


# ============================================================
# CLI 入口
# ============================================================

def main():
    import argparse

    ap = argparse.ArgumentParser(
        description="将视频链接或图文教程转换为 Cookmate 菜谱 JSON 格式",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例：
  python recipe_extractor.py https://www.youtube.com/watch?v=xxxxx
  python recipe_extractor.py https://www.bilibili.com/video/BVxxxxx
  python recipe_extractor.py https://www.xiachufang.com/recipe/xxxxx
  python recipe_extractor.py <URL> --output recipe.json
  python recipe_extractor.py <URL> --provider anthropic --model claude-3-5-sonnet-20241022
  python recipe_extractor.py <URL> --provider kimi --model moonshot-v1-32k
  python recipe_extractor.py <URL> --no-resolve   # 跳过 ID 解析，仅输出原始名称

环境变量（LLM）：
  OPENAI_API_KEY      使用 OpenAI 时必填
  ANTHROPIC_API_KEY   使用 Anthropic 时必填
  MOONSHOT_API_KEY    使用 Kimi 时必填

环境变量（Cookmate API - 食材 ID 解析）：
  COOKMATE_API_URL    API 地址，默认 http://localhost:8080/api
  COOKMATE_TOKEN      JWT Token（优先）
  COOKMATE_EMAIL      登录邮箱（COOKMATE_TOKEN 未设置时使用）
  COOKMATE_PASSWORD   登录密码
""",
    )
    ap.add_argument("url", help="要解析的 URL（YouTube 视频 / Bilibili 视频 / 图文网页）")
    ap.add_argument(
        "--provider",
        choices=["openai", "anthropic", "kimi"],
        default="openai",
        help="LLM 提供商（默认：openai）",
    )
    ap.add_argument(
        "--model",
        default=None,
        help=(
            "模型名称（OpenAI 默认 gpt-4o，Anthropic 默认 claude-3-5-sonnet-20241022，"
            "Kimi 默认 moonshot-v1-32k）"
        ),
    )
    ap.add_argument(
        "--output", "-o",
        help="输出 JSON 文件路径（默认输出到 stdout）",
    )
    ap.add_argument(
        "--no-resolve",
        action="store_true",
        help="跳过 Cookmate API 食材 ID 解析，仅输出原始名称",
    )
    args = ap.parse_args()

    default_models = {
        "openai": "gpt-4o",
        "anthropic": "claude-3-5-sonnet-20241022",
        "kimi": "moonshot-v1-32k",
    }
    if args.model is None:
        args.model = default_models[args.provider]

    key_map = {
        "openai": "OPENAI_API_KEY",
        "anthropic": "ANTHROPIC_API_KEY",
        "kimi": "MOONSHOT_API_KEY",
    }
    key_env = key_map[args.provider]
    if not os.environ.get(key_env):
        print(f"错误：请设置环境变量 {key_env}", file=sys.stderr)
        sys.exit(1)

    try:
        recipe = extract_recipe(
            url=args.url,
            provider=args.provider,
            model_name=args.model,
            resolve_ids=not args.no_resolve,
        )
        output_json = json.dumps(recipe, ensure_ascii=False, indent=2)

        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(output_json)
            print(f"[+] 菜谱已保存至 {args.output}", file=sys.stderr)
        else:
            print(output_json)

    except KeyboardInterrupt:
        print("\n已中断", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"错误：{e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
