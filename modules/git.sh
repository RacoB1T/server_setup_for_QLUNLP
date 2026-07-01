#!/usr/bin/env bash
# git.sh — Git 安装 + 全局配置模块

install_git() {
    if cmd_exists git; then
        log_skip "Git $(git --version | head -1) 已安装"
    else
        pkg_install git
        log_success "Git 安装完成"
    fi

    # 配置 Git 全局参数（若设置了值）
    if [ -n "${GIT_USER_NAME:-}" ]; then
        git config --global user.name "$GIT_USER_NAME"
        log_info "git config user.name = $GIT_USER_NAME"
    fi
    if [ -n "${GIT_USER_EMAIL:-}" ]; then
        git config --global user.email "$GIT_USER_EMAIL"
        log_info "git config user.email = $GIT_USER_EMAIL"
    fi
    if [ -n "${GIT_DEFAULT_BRANCH:-}" ]; then
        git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"
        log_info "git config init.defaultBranch = $GIT_DEFAULT_BRANCH"
    fi

    return 0
}

verify_git() {
    cmd_exists git
}
