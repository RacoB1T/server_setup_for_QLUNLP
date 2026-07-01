#!/usr/bin/env bash
# clash.sh — Clash (mihomo) 安装模块
# 封装已有的 clash-for-linux-install-master 安装器

install_clash() {
    local clash_src="$SETUP_DIR/clash-for-linux-install-master"
    local clash_env="$clash_src/.env"
    local clash_dir="${CLASH_BASE_DIR:-$HOME/clashctl}"

    # 1. 幂等检查：clashctl 命令是否存在
    if [ -d "$clash_dir" ] && [ -f "$clash_dir/scripts/cmd/clashctl.sh" ]; then
        log_skip "Clash 已安装: $clash_dir"
        # 确保 clashctl 可被 source
        if ! cmd_exists clashctl; then
            log_warn "clashctl 命令未在 PATH 中，添加 rc 引用"
            # shellcheck disable=SC1090
            [ -f "$clash_dir/scripts/cmd/clashctl.sh" ] && \
                . "$clash_dir/scripts/cmd/clashctl.sh"
        fi
        return 0
    fi

    # 2. 安装系统依赖
    log_info "安装 Clash 所需系统依赖..."
    local deps=(curl wget xz-utils unzip tar gzip)
    for dep in "${deps[@]}"; do
        if ! cmd_exists "$dep" && ! pkg_is_installed "$dep"; then
            pkg_install "$dep"
            break  # pkg_install 已经批量安装了
        fi
    done

    # 3. 检查 clash 安装器是否存在
    if [ ! -f "$clash_src/install.sh" ]; then
        log_error "找不到 clash 安装器: $clash_src/install.sh"
        return 1
    fi

    # 4. 注入配置到 .env
    log_info "准备 Clash 安装配置..."

    # 备份原始 .env
    cp "$clash_env" "$clash_env.bak"

    if [ -n "${CLASH_KERNEL:-}" ]; then
        sed -i "s/^KERNEL_NAME=.*/KERNEL_NAME=$CLASH_KERNEL/" "$clash_env"
    fi
    if [ -n "${CLASH_BASE_DIR:-}" ]; then
        # 将 ~ 展开为 $HOME 再写入
        local expanded_dir="${CLASH_BASE_DIR/\~/$HOME}"
        sed -i "s|^CLASH_BASE_DIR=.*|CLASH_BASE_DIR=$expanded_dir|" "$clash_env"
    fi
    if [ -n "${GH_PROXY:-}" ]; then
        sed -i "s|^URL_GH_PROXY=.*|URL_GH_PROXY=$GH_PROXY|" "$clash_env"
    fi
    if [ -n "${CLASH_SUBSCRIBE_URL:-}" ]; then
        sed -i "s|^CLASH_CONFIG_URL=.*|CLASH_CONFIG_URL=$CLASH_SUBSCRIBE_URL|" "$clash_env"
    fi

    # 5. 运行已有安装器
    log_info "运行 Clash 安装器..."
    cd "$clash_src"

    local install_args=()
    if [ -n "${CLASH_KERNEL:-}" ] && [ -n "${CLASH_SUBSCRIBE_URL:-}" ]; then
        install_args=("$CLASH_KERNEL" "$CLASH_SUBSCRIBE_URL")
    elif [ -n "${CLASH_KERNEL:-}" ]; then
        install_args=("$CLASH_KERNEL")
    fi

    if bash install.sh "${install_args[@]}"; then
        log_success "Clash 安装完成"
        cd "$SETUP_DIR"
        return 0
    else
        log_error "Clash 安装失败"
        # 恢复原始 .env
        mv "$clash_env.bak" "$clash_env"
        cd "$SETUP_DIR"
        return 1
    fi
}

verify_clash() {
    local clash_dir="${CLASH_BASE_DIR:-$HOME/clashctl}"
    [ -d "$clash_dir" ] && [ -f "$clash_dir/scripts/cmd/clashctl.sh" ]
}
