# dsh-TUI 0.12.0，给本仓库的 dsh 内核（0.2.0-rc.2）用的本地打包。
#
# 为什么不直接用上游 pkgs/bundles/tui：
#   上游 deepseek-harness.nix rev 9f53b70 把内核升到了 0.2.0-rc.2
#   (commit 150be1c)，但 bundles.tui 还钉在 dsh-TUI v0.11.2。它的
#   peerDependencies 只列到 0.2.0-rc.1，dshBundleCheckHook 在 installCheckPhase
#   直接判定不兼容并 exit 1（`nix run #presets.tui` 同样坏）。上游 HEAD（2026-10-01）
#   最后一个 bundles.tui 提交仍是 10dd3bb "0.11.1 -> 0.11.2"，没有现成修复可抄。
#
#   dsh-TUI v0.12.0 已把 0.2.0-rc.2 加进 peer 范围（pnpm-workspace.yaml 的 overrides
#   把整个 @deepseek-ai 树钉到 0.2.0-rc.2），所以换到它是正解。
#
# 相对上游 0.11.2 打包的三处改动（其余逐行照抄，见下方注释）：
#   1. postPatch 不再 chmod dsh-auth：0.12.0 删掉了这个 submodule。
#   2. prePnpmInstall 不再 `pnpm --dir dsh-auth install`：同上。
#   3. installPhase 不再把 node_modules/@deepseek-harness-tui/dsh-auth 从
#      workspace 链接拷成实体：0.12.0 里 dsh-auth 已不在 bundle 依赖里
#      （package.json 无 @deepseek-harness-tui/* 依赖，全仓只有 standalone/ 引用
#      @deepseek-ai/dsh-authorization）。
#   保留：btw-side-question-settle.patch（对 0.12.0 干净 apply，已 git apply --check
#   验证）、verify-i18n 与 verify-protocol-single-source 的 sandbox 替换（0.12.0 里
#   那三行源码文本逐字未变，--replace-fail 可继续生效）。
#
# 上游 bump bundles.tui 到 >= 0.12.0 后，删掉本文件与 pkgs/default.nix 里的覆盖。
{
  lib,
  fetchFromGitHub,
  fetchPnpmDeps,
  buildDshBundle,
  copyTree,
  dsh-kernel,
  pnpmConfigHook,
  pnpm_11,
}:
buildDshBundle (finalAttrs: {
  pname = "dsh-tui";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "ccch1mneyyy";
    repo = "dsh-TUI";
    rev = "refs/tags/v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-19XGm5spsmeo7leLKosxJiBxrMhBn2Cfy/CGYN6Q2os=";
  };

  # The side-question probe still needs its render-settle patch.
  patches = [ ./btw-side-question-settle.patch ];

  postPatch = ''
    # 0.12.0 移除了 dsh-auth submodule，故不再 chmod 它。
    chmod -R u+w vendor/dsh-std dsh-ecosystem-spec

    # fetchFromGitHub provides a tarball without a Git index, but these gates
    # only need the source file list for their static scan. Both files spell
    # the call identically, so one replacement each covers them.
    # verify-minimal-ui-naming.ts is 0.12.0-only: it grew a second `git ls-files`
    # gate (RETIRED_IDENTIFIERS scan) and was never covered upstream.
    for gate in scripts/verify-i18n.ts scripts/verify-minimal-ui-naming.ts; do
      substituteInPlace "$gate" \
        --replace-fail \
          "execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard', '--', 'src', 'scripts'], { encoding: 'utf8' })" \
          "execFileSync('find', ['src', 'scripts', '-type', 'f', '-print0'], { encoding: 'utf8' })"
    done

    # Submodules lack a .git directory in the Nix sandbox.
    substituteInPlace scripts/verify-protocol-single-source.ts \
      --replace-fail \
        "const head = execFileSync('git', ['-C', specGitDir, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim()" \
        "const { ECOSYSTEM_SPEC_REVISION: head } = await import('../src/adapter/standard/registry.js')" \
      --replace-fail \
        "const status = execFileSync('git', ['-C', specGitDir, 'status', '--short'], { encoding: 'utf8' }).trim()" \
        "const status = \"\""

  '';

  # Static imports initialize i18n before the verification script can set its
  # process-local language; pin build-time UI assertions in the locale-less Nix sandbox.
  env = {
    DSH_TUI_LANG = "en";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    postPatch = finalAttrs.postPatch;
    prePnpmInstall = ''
      # 0.12.0 没有 dsh-auth workspace 了，只剩 vendor/dsh-std。
      pnpm --dir vendor/dsh-std install \
        --ignore-scripts \
        --frozen-lockfile \
        --registry="$NIX_NPM_REGISTRY"
    '';
    hash = "sha256-wb6r6Lh7dLRZNWD5w/B/azRqV4mlr9QrgEbftx1nwr4=";
  };

  nativeBuildInputs = [ pnpm_11 ];
  disallowedReferences = [ pnpm_11 ];
  linkKernelNodeModules = dsh-kernel;
  # dsh-tui compiles against React 19, while dsh-kernel carries React 18.
  # supports-hyperlinks@3.2.0 needs the supports-color@7 function export,
  # while dsh-kernel carries 9.x.
  linkKernelNodeModulesKeep = [
    "ansi-styles"
    "react"
    "supports-color"
  ];

  npmDeps = null;
  npmConfigHook = pnpmConfigHook;
  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    appDir="$out/lib/node_modules/@deepseek-harness-tui/dsh-tui"
    mkdir -p "$appDir"

    # lib/ 由 npmBuildScript 的 tsc 生成（tsconfig outDir=lib/types），不是源码目录。
    cp -r package.json cordis.patch.yml cordis.yml dsh-ecosystem-spec presets lib "$appDir/"
    # Bundle-private deps such as auto-bind and dsh-working-activity are not in
    # the kernel; linkKernelNodeModules merges the kernel peers into this tree.
    cp -r node_modules "$appDir/node_modules"

    # Workspace links point into vendor/dsh-std, which is not installed.
    rm -rf "$appDir/node_modules/@dsh-std"
    ${copyTree.followLinks {
      src = "node_modules/@dsh-std";
      dest = "$appDir/node_modules/@dsh-std";
    }}

    runHook postInstall
  '';

  passthru = {
    inherit (finalAttrs) pnpmDeps;
    requiresTui = true;
    requiresTty = true;
  };

  meta = {
    description = "Interactive terminal interface for dsh";
    descriptions.zh-CN = "dsh 的交互式终端界面";
    homepage = "https://github.com/ccch1mneyyy/dsh-TUI";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
