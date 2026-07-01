#!/usr/bin/env bash
# codex.sh — Codex CLI (OpenAI) 安装模块

install_codex() {
    # 确保 Node.js 环境可用
    load_nvm

    if ! cmd_exists node; then
        log_error "Node.js 未找到，请先运行 node 模块"
        return 1
    fi

    if ! cmd_exists npm; then
        log_error "npm 未找到，请先运行 node 模块"
        return 1
    fi

    if cmd_exists codex; then
        local version
        version=$(codex --version 2>/dev/null || echo "unknown")
        log_skip "Codex CLI ($version) 已安装"
        return 0
    fi

    log_info "正在通过 npm 安装 @openai/codex ..."
    npm install -g @openai/codex

    log_success "Codex CLI 安装完成"
    return 0
}

verify_codex() {
    cmd_exists codex
}
