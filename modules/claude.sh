#!/usr/bin/env bash
# claude.sh — Claude Code 安装模块

install_claude() {
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

    if cmd_exists claude; then
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        log_skip "Claude Code ($version) 已安装"
        return 0
    fi

    log_info "正在通过 npm 安装 @anthropic-ai/claude-code ..."
    npm install -g @anthropic-ai/claude-code

    log_success "Claude Code 安装完成"
    return 0
}

verify_claude() {
    cmd_exists claude
}
