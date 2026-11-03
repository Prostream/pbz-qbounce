# PBZ QBounce · 影之刃零 Q 弹 Mod

Make the player, enemies and NPCs squash and stretch together in **Phantom Blade Zero**.
让《影之刃零》的主角、敌人和 NPC 一起有节奏地压扁、拉长。

**[下载 / Download](https://github.com/Prostream/pbz-qbounce/releases/latest)** · [中文安装指南](#中文安装指南) · [English installation guide](#english-installation-guide)

Version **0.1.0** · Windows / Steam · UE4SS Lua mod

## 中文安装指南

### 已验证环境

- Steam build **26266538**，游戏程序版本 **CL-301524_JKS-17219**。
- 前置为 [KintaroModding 的 PBZ 专用 UE4SS](https://github.com/KintaroModding/ue4ss/releases/tag/v3.0.1-1183-gcdbc0b66)，版本 `v3.0.1-1183-gcdbc0b66`。
- 2026-10-29 已实机确认主角和敌人正常 Q 弹。尚未覆盖所有敌人、Boss、服装或后续游戏版本。
- 发布包只包含本 mod 的 Lua 脚本和说明；UE4SS 需单独安装，不包含游戏文件或背景音乐。

### 1. 找到正确的游戏目录

退出游戏。在 Steam 库中右键游戏 → 管理 → 浏览本地文件，打开 `platform\steam`。

下文的 `<PBZ>` 表示你的游戏根目录。正确位置是：

```text
<PBZ>\platform\steam\PBZ.exe
```

这里是实际运行游戏的程序目录。不要装到根目录下另一个 `steam` 启动器目录，也不要装到 `ProjectPBZ\Binaries\Win64`。

### 2. 安装 UE4SS 前置

如果已安装并正常运行上述 PBZ 专用 UE4SS，可保留现有前置，继续第 3 步。

1. 从[前置发布页](https://github.com/KintaroModding/ue4ss/releases/tag/v3.0.1-1183-gcdbc0b66)下载 `phantombladezero_ue4ss_v3.0.1-1183-gcdbc0b66.zip`。
2. 将压缩包里的 `dwmapi.dll` 和整个 `ue4ss` 文件夹复制到 `<PBZ>\platform\steam`，使 DLL 与 `PBZ.exe` 同级。保留包内的布局和签名配置，不要只复制 DLL。
3. 若这个位置已有其他加载器，先备份并确认兼容性，不要直接覆盖。
4. 在 `ue4ss\UE4SS-settings.ini` 的 `[General]` 段中确认以下两项为 `0`（指定前置包已如此设置）。修改 mod 配置后请重启游戏，不要使用热重载。

```ini
EnableHotReloadSystem = 0
EnableAutoReloadingLuaMods = 0
```

### 3. 安装并启用 QBounce

1. 从[本项目 Releases](https://github.com/Prostream/pbz-qbounce/releases/latest)下载 **`PBZ-QBounce-0.1.0-mod-only.zip`**，不是 GitHub 自动生成的 `Source code` 压缩包。
2. 解压，将其中的整个 **`PBZ_QBounce` 文件夹**复制到 `<PBZ>\platform\steam\ue4ss\Mods`。
3. 编辑 `ue4ss\Mods\mods.txt`。首次安装、没有其他 mod 时，将内容设为下面两行，只启用本 mod 和内置按键模块：

```text
PBZ_QBounce : 1
Keybinds : 1
```

已有其他 mod 时，保留需要的条目，在 `Keybinds` 前添加或更新 `PBZ_QBounce : 1`，不要重复添加。前置包附带的 `BPModLoaderMod` 和 `BPML_GenericFunctions` 不用于本 mod；本项目的已验证配置将它们关闭（对应条目改为 `: 0`）。

最终目录应为：

```text
<PBZ>/platform/steam/
├── PBZ.exe
├── dwmapi.dll
└── ue4ss/
    ├── UE4SS.dll
    ├── UE4SS-settings.ini
    ├── MemberVariableLayout.ini
    ├── UE4SS_Signatures/
    └── Mods/
        ├── mods.txt
        ├── shared/UEHelpers/UEHelpers.lua
        ├── Keybinds/Scripts/main.lua
        └── PBZ_QBounce/Scripts/
            ├── main.lua
            ├── bounce.lua
            └── config.lua
```

4. 从 Steam 正常启动，进入可以操控主角的场景，等约 **2 秒**。默认自动开启，周围敌人和 NPC 也会加入。主菜单不适合检查效果。

### 快捷键与强度

| 按键 | 功能 |
| --- | --- |
| F6 | 开关 Q 弹；关闭时尝试恢复记录的原始尺寸 |
| F7 | 在 `0.25 → 0.5 → 0.7 → 0.25` 强度之间循环；默认 `0.4` 启动后第一次按下会切到 `0.7` |
| F8 | 重置节拍，方便录屏后配乐 |
| F9 | 立即扫描，将角色与缩放诊断写入日志 |

编辑 `<PBZ>\platform\steam\ue4ss\Mods\PBZ_QBounce\Scripts\config.lua` 后，**重启游戏生效**。F7 的临时调整不会保存到文件。

| 配置 | 默认值 | 含义 |
| --- | --- | --- |
| `Stretch` | `0.4` | 高度在原尺寸的 60%～140% 之间变化；`0.25` 更轻，`0.5` 更夸张；允许 `0`～`0.85` |
| `PeriodSeconds` | `0.45` | 完成一次伸缩的秒数；越大越慢 |
| `PoissonRatio` | `0.5` | 横向与竖向反向变化的比例；默认横向为原尺寸的 80%～120% |
| `AffectPlayer` | `true` | 是否影响主角 |
| `AffectOthers` | `true` | 是否影响敌人及 NPC |
| `RadiusMeters` | `80.0` | 玩家周围扫描半径，单位为米 |

### 停用、卸载与排查

- **临时关闭：**游戏内按 F6。
- **下次启动停用：**退出游戏，把 `mods.txt` 中本 mod 的条目改为 `PBZ_QBounce : 0`。
- **卸载本 mod：**退出游戏，删除 `ue4ss\Mods\PBZ_QBounce` 文件夹，并移除对应的 `mods.txt` 条目。保留其他 mod 使用的 UE4SS。
- **没效果：**检查目录是否多套了一层、`mods.txt` 是否启用、是否已进入实际游戏；按 F9 后查看 `<PBZ>\platform\steam\ue4ss\UE4SS.log` 中的 `[PBZ-QBounce]` 和 `ERROR`。
- **装前置后无法启动：**退出游戏，将这次安装的 `dwmapi.dll` 暂时改名为 `dwmapi.dll.disabled` 以停用该加载器，然后确认前置与游戏版本是否匹配。这也会停用依赖它的其他 mod。
- **提交问题：**附游戏 build、UE4SS 版本、复现步骤和相关日志片段；分享前请去掉个人路径等信息。

效果作用于角色骨骼网格，是压扁／拉长，不会额外添加离地跳跃。每两秒扫描当前世界内的 Pawn 角色，最多处理 128 个独立网格，跳过已继承目标父网格缩放的子网格。不会写入存档，也不主动缩放移动根组件或摄像机；网格关联的物理、布料及武器轨迹仍可能受影响。特殊 Boss 或被游戏持续重置缩放的模型可能需要额外适配。

## English installation guide

### Tested setup

- Steam build **26266538**, executable version **CL-301524_JKS-17219**.
- Requires [KintaroModding's PBZ-specific UE4SS](https://github.com/KintaroModding/ue4ss/releases/tag/v3.0.1-1183-gcdbc0b66), version `v3.0.1-1183-gcdbc0b66`.
- The player and enemies were confirmed bouncing in-game on October 29, 2026. Every enemy, boss, outfit and later game version has not been tested.
- The release contains this mod's Lua scripts and instructions. Install UE4SS separately. No game files or music are included.

### 1. Locate the correct game folder

Close the game. In your Steam Library, right-click the game → Manage → Browse local files, then open `platform\steam`.
`<PBZ>` below means your game installation root. The correct executable is:

```text
<PBZ>\platform\steam\PBZ.exe
```

Use this actual game executable directory, not the separate `steam` launcher folder or `ProjectPBZ\Binaries\Win64`.

### 2. Install UE4SS

If the specified PBZ-specific UE4SS already works in your installation, keep it and proceed to step 3.

1. Download `phantombladezero_ue4ss_v3.0.1-1183-gcdbc0b66.zip` from the [loader release page](https://github.com/KintaroModding/ue4ss/releases/tag/v3.0.1-1183-gcdbc0b66).
2. Copy `dwmapi.dll` and the entire `ue4ss` folder from that archive into `<PBZ>\platform\steam`, beside `PBZ.exe`. Keep the supplied member-layout and signature files; copying only the DLLs is insufficient.
3. If another loader is already present, back it up and check compatibility before replacing anything.
4. In the `[General]` section of `ue4ss\UE4SS-settings.ini`, keep both settings below at `0`, as supplied in the specified loader. Restart the game after editing mod configuration; do not hot-reload it.

```ini
EnableHotReloadSystem = 0
EnableAutoReloadingLuaMods = 0
```

### 3. Install and enable QBounce

1. Download **`PBZ-QBounce-0.1.0-mod-only.zip`** from [this project's Releases](https://github.com/Prostream/pbz-qbounce/releases/latest), rather than GitHub's automatic `Source code` archive.
2. Extract it and copy the entire **`PBZ_QBounce` folder** into `<PBZ>\platform\steam\ue4ss\Mods`.
3. Edit `ue4ss\Mods\mods.txt`. For a fresh installation with no other mods, use these two lines to enable only QBounce and the built-in keybind module:

```text
PBZ_QBounce : 1
Keybinds : 1
```

If you already use other mods, preserve the entries you need and add or update `PBZ_QBounce : 1` before `Keybinds`, without duplicates. The loader's bundled `BPModLoaderMod` and `BPML_GenericFunctions` are not used here; the tested setup disables them (set their entries to `: 0`).

Verify that `main.lua` is at `<PBZ>\platform\steam\ue4ss\Mods\PBZ_QBounce\Scripts\main.lua`. The full directory tree is shown in the Chinese section above. Keep the loader's `shared\UEHelpers` folder.

4. Start the game normally through Steam, enter a playable scene and wait about **2 seconds**. The effect is enabled by default for the player and nearby enemies/NPCs. Check in gameplay, not only in the main menu.

### Controls and configuration

| Key | Action |
| --- | --- |
| F6 | Toggle the effect; disabling attempts to restore the recorded original scales |
| F7 | Cycle `0.25 → 0.5 → 0.7 → 0.25`; from the default `0.4`, the first press selects `0.7` |
| F8 | Reset the beat for recording and later music synchronization |
| F9 | Rescan and write actor/scale diagnostics to the log |

Edit `<PBZ>\platform\steam\ue4ss\Mods\PBZ_QBounce\Scripts\config.lua`, then **restart the game**. F7 adjustments are temporary and are not saved.

| Setting | Default | Meaning |
| --- | --- | --- |
| `Stretch` | `0.4` | Height varies between 60% and 140% of its original scale; try `0.25` for subtle or `0.5` for stronger deformation; allowed range: `0`–`0.85` |
| `PeriodSeconds` | `0.45` | Seconds per full cycle; higher values are slower |
| `PoissonRatio` | `0.5` | Opposing horizontal deformation ratio; the default horizontal range is 80%–120% |
| `AffectPlayer` | `true` | Affect the player |
| `AffectOthers` | `true` | Affect enemies and NPCs |
| `RadiusMeters` | `80.0` | Scan radius around the player, in meters |

### Disable, uninstall and troubleshoot

- **Temporarily disable:** press F6 in-game.
- **Disable on the next launch:** close the game and change the entry in `mods.txt` to `PBZ_QBounce : 0`.
- **Uninstall this mod:** close the game, remove `ue4ss\Mods\PBZ_QBounce`, and remove its entry from `mods.txt`. Keep UE4SS if other mods need it.
- **No effect:** check the folder nesting, enabled entry and whether you have entered gameplay. Press F9, then inspect `<PBZ>\platform\steam\ue4ss\UE4SS.log` for `[PBZ-QBounce]` and `ERROR`.
- **Cannot launch after installing the loader:** close the game and temporarily rename the `dwmapi.dll` installed in step 2 to `dwmapi.dll.disabled`. Check the loader/game version match. This also disables other mods that depend on that loader.
- **Reporting an issue:** include your game build, UE4SS version, reproduction steps and relevant log excerpts. Remove personal paths before sharing.

This is skeletal-mesh squash/stretch, with no added upward translation. It scans Pawn characters in the current world every two seconds, targets up to 128 independent meshes, and skips child meshes that already inherit a targeted parent's scale. It does not write saves or directly scale the movement root or camera. Mesh physics, cloth and weapon traces may still be affected. Unusual bosses or models whose scale is constantly reset by the game may require additional support.

## Development / 开发

Python **3.10+** is used for packaging and tests; players do not need Python.
打包和离线测试需要 Python **3.10+**，普通玩家安装 mod 不需要 Python。

```powershell
python -m pip install -r requirements-dev.txt
python tests/test_mod.py
python tools/build.py
```

The default build creates the mod-only ZIP and `SHA256SUMS.txt` in `dist/`, without downloading dependencies or bundling UE4SS. The 13 Lua 5.4 mock tests cover waveform extrema, original-scale restoration, child meshes, map changes, destroyed objects, distance filtering, bounded queued work and frame-rate independence. These are not a substitute for in-game testing.

默认构建在 `dist/` 生成 mod 压缩包和校验文件，不下载或打包 UE4SS。13 项 Lua 5.4 模拟测试覆盖波形、尺寸恢复、子网格、切图、对象销毁、距离筛选、队列和帧率独立性；不能替代实机测试。

For a **fresh local development installation** of the exact tested loader, the optional commands below fetch the pinned, SHA-256-verified upstream package and stage it locally. The installer refuses existing loader files and a different executable version. Supply your own game root. The full local bundle is not a GitHub release asset.

如需使用已验证前置进行**全新的本地开发安装**，下面的可选命令会下载固定版本并校验 SHA-256。安装器拒绝覆盖已有加载器，并检查游戏程序版本；请填写自己的游戏根目录。包含前置的本地包不作为 GitHub 发布附件。

```powershell
python tools/fetch_sources.py
python tools/build.py --with-loader
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -GameRoot 'C:\your\SteamLibrary\steamapps\common\PBZ'
```

## Credits / 致谢

- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) and [KintaroModding's PBZ loader adaptation](https://github.com/KintaroModding/ue4ss).
- [Phantom Blade Zero WitchTime](https://github.com/KintaroModding/phantombladezero_witchtime) for examples of game-thread scheduling and player access. It is not required or bundled.
- Inspired by the Monster Hunter Q-bounce / 邦友的酒 effect. The sinusoidal effect was independently implemented for Unreal; no Monster Hunter memory addresses, original mod scripts or music are distributed.
- 效果参考怪猎 Q 弹／邦友的酒，在 Unreal 中独立实现；未分发怪猎内存地址、原 mod 脚本或音乐。第三方前置请遵循其各自的许可。
