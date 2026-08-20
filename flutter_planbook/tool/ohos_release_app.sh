#!/usr/bin/env bash
# 鸿蒙上架包构建脚本：产出 AGC 可上传的发布证书签名 .app
#
# 原理：仓库里的 ohos/build-profile.json5 只保留调试签名（日常开发用），
# 发布签名材料（p12/cer/p7b/密码）全部放在 ~/.ohos/sign/release/，不进仓库。
# 流程：临时摘掉 product 的 signingConfig → 构建未签名 .app →
#       用 SDK 的 hap-sign-tool.jar 以发布证书本地签名 → 恢复配置。
#
# 用法：tool/ohos_release_app.sh
# 产出：build/ohos/outputs/planbook-<versionName>-<versionCode>-release.app
#       （与 Android build/app/outputs、iOS build 产物同级，位于 Flutter 工程 build/ 下）
set -euo pipefail

cd "$(dirname "$0")/.."

SIGN_DIR="$HOME/.ohos/sign/release"
P12="$SIGN_DIR/planbook.p12"
CER="$SIGN_DIR/planbook.cer"
P7B="$SIGN_DIR/planbookRelease.p7b"
PW_FILE="$SIGN_DIR/PASSWORDS.txt"
PROFILE="ohos/build-profile.json5"
SIGN_TOOL_JAR="$HOME/Library/OpenHarmony/Sdk/23/toolchains/lib/hap-sign-tool.jar"
JAVA_BIN="${JAVA_BIN:-java}"
OUT_DIR="build/ohos/outputs"

for f in "$P12" "$CER" "$P7B" "$PW_FILE" "$SIGN_TOOL_JAR"; do
  if [ ! -f "$f" ]; then
    echo "缺少签名材料: $f（参见 docs/ohos_integration.md §7）" >&2
    exit 1
  fi
done

PW=$(awk '/storePassword/{print $2}' "$PW_FILE")
VERSION_NAME=$(python3 -c "import re;print(re.search(r'\"versionName\": \"([^\"]+)\"', open('ohos/AppScope/app.json5').read()).group(1))")
VERSION_CODE=$(python3 -c "import re;print(re.search(r'\"versionCode\": (\d+)', open('ohos/AppScope/app.json5').read()).group(1))")
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/planbook-${VERSION_NAME}-${VERSION_CODE}-release.app"

# 1. 临时摘掉 product 的 signingConfig（hvigor 无配置时产出未签名包）
cp "$PROFILE" /tmp/build-profile.json5.ohos-bak
restore() { cp /tmp/build-profile.json5.ohos-bak "$PROFILE"; }
trap restore EXIT
python3 - <<'EOF'
s = open('ohos/build-profile.json5').read()
s = s.replace('        "signingConfig": "default",\n', '')
open('ohos/build-profile.json5', 'w').write(s)
EOF

# 2. 构建未签名 .app（flutter 工具最后会因找不到签名包报错，属预期，忽略之）
fvm flutter build app --release --target lib/main_ohos.dart || true
UNSIGNED_APP="ohos/build/outputs/default/ohos-default-unsigned.app"
if [ ! -f "${UNSIGNED_APP}" ]; then
  echo "未找到未签名包 ${UNSIGNED_APP}，构建失败" >&2
  exit 1
fi

# 3. 发布证书签名 + 校验
"$JAVA_BIN" -jar "$SIGN_TOOL_JAR" sign-app \
  -keyAlias planbook_release \
  -signAlg SHA256withECDSA \
  -mode localSign \
  -appCertFile "$CER" \
  -profileFile "$P7B" \
  -inFile "${UNSIGNED_APP}" \
  -keystoreFile "$P12" \
  -outFile "$OUT" \
  -keyPwd "$PW" \
  -keystorePwd "$PW"

"$JAVA_BIN" -jar "$SIGN_TOOL_JAR" verify-app \
  -inFile "$OUT" \
  -outCertChain /tmp/ohos-release-chain.cer \
  -outProfile /tmp/ohos-release-profile.p7b

echo "上架包已产出（签名校验通过）：$OUT"
