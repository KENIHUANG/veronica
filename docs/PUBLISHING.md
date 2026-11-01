# 发布指南:GitHub 与 Steam

## 一、发到 GitHub
1. 注册并新建仓库(建议 Public),不要勾选自动生成 README(本项目已有)。
2. 在项目文件夹里:
   ```
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/<你的用户名>/<仓库名>.git
   git push -u origin main
   ```
   (`.gitignore` 已排除 `.godot/` 和构建产物。)
3. 选一个开源协议放进 `LICENSE`(代码常用 MIT)。你没有用任何第三方贴图/模型/字体/音频,所以只要保留 `CREDITS.md` 里的 Godot MIT 声明。
4. 在 README 里放几张截图和一个 GIF,点开就能看懂游戏是什么。
5. 网页试玩:
   - 编辑器里 项目 → 导出 → 添加 "Web",**关闭 Thread Support**(GitHub Pages 不能设置所需的响应头)。
   - 添加 "Windows Desktop"、"Linux" 预设,把 `export_presets.cfg` 提交。
   - 仓库 Settings → Pages → Source 选 "GitHub Actions"。之后每次 push,`.github/workflows/export.yml` 会自动导出并发布,地址形如 `https://<用户名>.github.io/<仓库名>/`。
6. 发布可下载版本:Releases → Draft a new release → 上传导出的 zip。

## 二、发到 Steam(要点)
1. **账号与费用**:注册 Steamworks 开发者账号,完成身份/税务/银行信息,为每个游戏支付 Steam Direct 费用(目前每个游戏 100 美元,游戏累计收入达到 1000 美元后退还;付费后至少要等 30 天才能发布)。以官方页面为准:https://partner.steamgames.com/steamdirect
2. **商店页面**:标题、简介、系统要求、至少 5 张截图、胶囊图(多种尺寸)、预告片(强烈建议)。尽早创建 "即将推出" 页面(建议发布前至少 2 周),积累愿望单。
3. **导出构建**:Godot 导出 Windows(必要时 Linux)。用 SteamPipe(Steamworks SDK 里的 steamcmd)上传 depot,在后台把构建设为默认分支。
4. **商店提交审核**:商店页面和构建各自审核,通常几个工作日。需要填写内容调查问卷(这个游戏有恐怖/惊吓内容)和年龄分级。
5. **AI 披露(重要)**:Steam 要求在内容调查里披露游戏里"玩家会接触到的 AI 生成内容"。本游戏的剧情台词、英文翻译、以及程序生成的音效/贴图/模型有 AI 协助,请按 Steam 当前的问卷措辞如实勾选并写明(规则会更新,提交前重新读一遍)。
6. **发布前自查**
   - 日记里提到了真人名("巨石强森 type"):商业发布前请改成虚构称呼,避免肖像/名誉风险。
   - 不要在商店页面用 "Resident Evil / 生化危机" 做宣传词或标签;"Veronica" 与某款生化危机作品副标题重名,建议在商店里用完整标题 "Veronica: The Hair Lab" 并考虑是否换名。
   - 修女雕像的设计灵感来自电影《修女》,保持"泛指的修女石像"即可,不要使用任何官方名称或标志。
   - 在游戏或商店页面中保留 Godot 的 MIT 许可声明(见 CREDITS.md)。
   - 英文文本建议找母语者校对;最好再加一两种语言之前先看看你的受众在哪。
   - 成就、云存档等需要 GodotSteam 插件(可选,上架不强制)。
7. **可选**:Steam Deck 验证(本游戏有手柄之外的键鼠操作,需要加手柄支持后再申请);定价与区域定价;demo(可以先发一个免费 Demo 收愿望单)。

## 三、手机端
- **最省事**:导出 Web 版,手机浏览器打开(横屏),触控界面自动启用。
- **Android**:Godot 编辑器 项目 → 安装 Android 构建模板,配置 JDK 17 和 Android SDK,创建发布用 keystore,然后导出 APK/AAB。上架 Google Play 需要开发者账号(一次性 25 美元)。
- **iOS**:需要 macOS + Xcode + Apple Developer 账号(每年 99 美元)。
- 手机渲染默认使用 Compatibility 渲染器(已在项目设置里指定);低端机如果卡顿,可以降低 `scripts/mirror.gd` 里镜面视口分辨率(0.5 → 0.35)。
