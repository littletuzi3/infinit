#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/infinit.sh"

# 检查 Node.js 版本
NODE_VERSION=$(node -v 2>/dev/null)

if [ $? -ne 0 ] || [ "$(echo -e "$NODE_VERSION\nv22.0.0" | sort -V | head -n1)" != "v22.0.0" ]; then
    echo "Node.js 版本低于 22.0.0，正在安装..."

    # 安装 nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # 安装 Node.js 22
    nvm install 22
    nvm alias default 22
    nvm use default

    echo "Node.js 安装完成，当前版本: $(node -v)"
else
    echo "Node.js 已安装，当前版本: $NODE_VERSION"
fi

# 检查并安装 unzip
sudo apt-get install -y unzip

# 检查并安装 Bun
if ! command -v bun &> /dev/null; then
    echo "Bun 未安装，正在安装..."
    curl -fsSL https://bun.sh/install | bash
    source /root/.bashrc
    echo "Bun 安装完成"
else
    echo "Bun 已安装"
fi

# 创建项目目录并进入
mkdir infinit
cd infinit

# 初始化 Bun 项目
bun init -y

# 安装 @infinit-xyz/cli
bun add @infinit-xyz/cli

# 初始化 Infinit
bunx infinit init

# 创建账户
ACCOUNT_ID=$(bunx infinit account generate)

# 显示私钥提示
echo "Copy this private key and save it somewhere, this is the private key of this wallet"
echo
bunx infinit account export $ACCOUNT_ID

# 提示用户按任意键继续
read -n 1 -s -r -p "Press any key to continue..."

echo
# 移除旧的 deployUniswapV3Action 脚本（如果存在）
rm -rf src/scripts/deployUniswapV3Action.script.ts

# 创建新的 deployUniswapV3Action 脚本
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

# 执行 UniswapV3 Action 脚本
echo "Executing the UniswapV3 Action script..."
echo
bunx infinit script execute deployUniswapV3Action.script.ts
