#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/infinit.sh"

# 显示 Logo
curl -s https://raw.githubusercontent.com/sdohuajia/Hyperlane/refs/heads/main/logo.sh | bash
sleep 3

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "================================================================"
        echo "节点社区 Telegram 群组: https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道: https://t.me/niuwuriji"
        echo "节点社区 Discord 社群: https://discord.gg/GbMV5EcNWF"
        echo "退出脚本，请按键盘 ctrl+c 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 部署合约"
        echo "2) 退出"

        read -p "请输入选择: " choice

        case $choice in
            1)
                deploy_contract
                ;;
            2)
                echo "退出脚本..."
                exit 0
                ;;
            *)
                echo "无效选择，请重试"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# 检查并安装命令
function check_install() {
    command -v "$1" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "$1 未安装，正在安装..."
        eval "$2"
    else
        echo "$1 已安装"
    fi
}

# 部署合约
function deploy_contract() {
    export NVM_DIR="$HOME/.nvm"
    
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
        source "$NVM_DIR/nvm.sh"
    fi

    # 检查并安装 Node.js
    if ! command -v node &> /dev/null; then
        nvm install 22
        nvm alias default 22
        nvm use default
    fi
    
    show "安装 Foundry..."
    echo
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    sleep 5
    source ~/.bashrc
    foundryup
    
    # 检查并安装 Bun
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
        export PATH="$HOME/.bun/bin:$PATH"  # 更新 PATH
        sleep 5
        source "$HOME/.bashrc"  # 确保环境变量生效
    fi

    # 检查 Bun 是否存在
    if ! command -v bun &> /dev/null; then
        echo "Bun 未安装，安装可能失败，请检查安装步骤"
        exit 1
    fi

    # 设置 Bun 项目
    mkdir -p infinit && cd infinit || exit
    bun init -y

    echo "正在初始化 Infinit CLI 并生成帐户..."
    bunx infinit init
    bunx infinit account generate
    echo

    read -p "您的钱包地址是什么（输入上面步骤中的地址） : " WALLET
    echo
    read -p "您的帐户 ID 是什么（在上面的步骤中输入） : " ACCOUNT_ID
    echo

    show "复制这个私钥并保存在某个地方，这是这个钱包的私钥"
    echo
    bunx infinit account export $ACCOUNT_ID

    sleep 5
    echo
    # Removing old deployUniswapV3Action script if exists
    rm -rf src/scripts/deployUniswapV3Action.script.ts

    
cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// TODO: Replace with actual params
const params: Param = {
  // Native currency label (e.g., ETH)
  "nativeCurrencyLabel": 'ETH',

  // Address of the owner of the proxy admin
  "proxyAdminOwner": '$WALLET',

  // Address of the owner of factory
  "factoryOwner": '$WALLET',

  // Address of the wrapped native token (e.g., WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Signer configuration
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

    echo "正在执行 UniswapV3 Action 脚本..."
    bunx infinit script execute deployUniswapV3Action.script.ts

    read -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
