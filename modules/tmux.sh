#!/usr/bin/env bash
# tmux.sh — tmux 终端复用器安装模块

install_tmux() {
    if cmd_exists tmux; then
        log_skip "tmux $(tmux -V 2>/dev/null) 已安装"
    else
        log_info "安装 tmux..."
        pkg_install tmux
        log_success "tmux 安装完成"
    fi

    return 0
}

verify_tmux() {
    cmd_exists tmux
}
