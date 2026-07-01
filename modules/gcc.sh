#!/usr/bin/env bash
# gcc.sh — GCC/G++ 编译工具链安装模块

install_gcc() {
    if cmd_exists gcc && cmd_exists g++; then
        log_skip "GCC $(gcc --version 2>/dev/null | head -1) 已安装"
        log_skip "G++ $(g++ --version 2>/dev/null | head -1) 已安装"
    else
        log_info "安装 GCC/G++ 编译工具链..."
        pkg_install gcc g++ make
        log_success "GCC/G++ 安装完成"
    fi

    return 0
}

verify_gcc() {
    cmd_exists gcc && cmd_exists g++
}
