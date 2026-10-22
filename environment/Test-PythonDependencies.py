"""Check the development SDKs offline; no model, service, or business app is started."""

from __future__ import annotations

import importlib
import importlib.metadata
import json
import os
import sys
from pathlib import Path


def main() -> None:
    os.environ["LANGSMITH_TRACING"] = "false"
    os.environ["LANGCHAIN_TRACING_V2"] = "false"
    expected_venv = Path(__file__).resolve().parent.parent / ".venv"
    if sys.version_info[:2] != (3, 11) or Path(sys.prefix).resolve() != expected_venv:
        raise RuntimeError("Use the workspace Python 3.11 virtual environment.")

    packages = {
        "fastapi": "fastapi",
        "uvicorn": "uvicorn",
        "langchain": "langchain",
        "langchain-core": "langchain_core",
        "langgraph": "langgraph.graph",
        "langgraph-checkpoint": "langgraph.checkpoint",
        "mcp": "mcp",
        "httpx": "httpx",
        "python-dotenv": "dotenv",
        "elasticsearch": "elasticsearch",
        "redis": "redis",
        "minio": "minio",
        "pymysql": "pymysql",
        "pypdf": "pypdf",
    }
    versions = {}
    for package, module in packages.items():
        importlib.import_module(module)
        versions[package] = importlib.metadata.version(package)

    from fastapi import FastAPI
    from fastapi.testclient import TestClient
    from langchain_core.prompts import ChatPromptTemplate
    from langgraph.graph import END, START, StateGraph
    from typing_extensions import TypedDict

    # Exercise in-memory request handling and graph execution, with no open port.
    app = FastAPI()

    @app.get("/environment-check")
    def environment_check() -> dict[str, bool]:
        return {"ok": True}

    with TestClient(app) as client:
        response = client.get("/environment-check")
        if response.status_code != 200 or response.json() != {"ok": True}:
            raise RuntimeError("FastAPI in-memory request failed.")

    class State(TypedDict):
        value: int

    graph = StateGraph(State)
    graph.add_node("check", lambda state: {"value": state["value"] + 1})
    graph.add_edge(START, "check")
    graph.add_edge("check", END)
    result = graph.compile().invoke({"value": 1})
    if result["value"] != 2:
        raise RuntimeError("LangGraph execution failed.")
    prompt = ChatPromptTemplate.from_messages([("human", "{value}")])
    if prompt.invoke({"value": "environment-check"}).to_messages()[0].content != "environment-check":
        raise RuntimeError("LangChain prompt handling failed.")

    print(json.dumps({"status": "PASS", "packages": versions, "fastapi": "PASS", "langgraph": "PASS"}))


if __name__ == "__main__":
    main()
