# 交接说明(给接手的 AI)
见对话里给用户的完整提示词。本文件是同一份内容的摘要,放在仓库里方便查阅。
- 引擎:Godot 4.3,GDScript,3D 第一人称恐怖喜剧《Veronica: 生发剂实验室》
- 文案以中文原文为键,英文在 scripts/en_strings.gd
- 无头测试脚本在 tests/;截图测试需要 xvfb + lavapipe(见提示词)

## v5 进度(A 视觉收尾已完成)
- 一键回归:`GODOT=/path/to/godot tests/run_all.sh`(`SHOTS=1` 额外截图,需 xvfb-run;默认用 opengl3 = Compatibility 渲染器,没有软件 Vulkan 时也能截图)。
- 截图脚本都读环境变量 `SHOT_DIR`:pic_sheet(全部挂画对照)、shot_frames、shot_statue、shots2(镜子)、shot_end、shot_boss、shot_lab2、shot_lab。
- Draw.face_texture 新参数:`socket`(空洞眼窝大小)、`pin`(眼窝里的光点颜色)、`black_tears`(黑色泪痕)。Draw._creepify() 是恐怖版挂画的后期。
- creepy_frame.gd 新增 apply_state();挂画材质改为哑光并压暗。
- mirror.gd:flicker_preview()(1~2 帧闪现)、故障抖动、扑玻璃时红闪;事件期间镜面分辨率 0.75,平时 0.5(res_scale / event_res_scale)。
- 文案修改方案见 docs/B_文案修改方案.md(未改代码,待用户确认)。

## v6 进度
- 文案:序幕改为「调查委托 #0417」报告体;新增开局道具「水样检测报告」(科普:米诺地尔排排停停 → 全镇长了又掉;小女孩体重轻离排污口近 → 长出胡子);接待台剪报交代抛硬币传闻;日记按"骄傲→偏执→崩溃→遗言"重写并去掉真人名;Boss 独白调节奏;修了"试了十年""空腔手枪"等矛盾。
- 字符串工具:`python3 tools/extract_strings.py --missing`(缺英文的中文)、`--doc`(重新生成 docs/script_all_zh.md)。
- PS1 复古画面:scripts/retro.gd(CanvasLayer 9,在 UI 之下),设置项 L.retro,暂停菜单可开关。
- 素材替换槽:scripts/asset_slots.gd;Person.build 的 "slot" 参数;props.toilet/sink、wigs.wig/mannequin、statue、mats.get_mat 都已接入。已用临时生成的 GLB/贴图验证过(play 测试通过),测试素材已删除。

## v7 进度
- 已接入真实素材(全部 CC0,见 CREDITS.md):Kenney 马桶/洗手台;Quaternius 写实身材烘焙成的白色塑料人体模型。
- asset_slots.gd 新增 NORMALIZE(每个槽的目标高度/旋转/落地/居中/靠墙)和 assets/models/slots.json 覆盖;支持 .fbx。
- tools/bake_pose.gd:把带骨骼人物摆成"双臂下垂"(或套动画库某帧,需同名骨骼)并烘焙为静态 GLB。
- 风格决定:主要角色(石像、Boss、镜中鬼、鬼魂、小女孩)保留程序化 + PS1 画面;Q 版角色包试过,太可爱,不用。

## v8 进度
- 墙上的字改成写实风格:印刷体标牌改为受光照(WB.label3d 默认 shaded,EXIT 灯箱 glow=true);厕所 3 号隔间改为血字 "HE IS STILL IN HERE."(scripts/blood_text.gd:手写字体渲染 → 血色、干涸边缘、淌血、溅点);办公室白板和实验室便利贴改为马克笔手写(scripts/handwriting.gd)。
- 字体:Permanent Marker(Apache 2.0)+ Long Cang(OFL),在 assets/fonts/,许可在 assets/fonts/LICENSES。
- 文案校对稿:docs/文案校对稿.md(25 条,待用户确认后执行)。

## v9 进度
- 文案校对稿 25 条全部落实(docs/文案校对稿.md),英文同步,删除了被替换掉的旧翻译键。
- 镇民来信(scripts/letters.gd):5 封,flag letter_0..4;背包物品 town_letters 可重读;收齐后结局河边多一段"把信还给母亲"。位置:大厅接待台信格(第 3 排)、厕所垃圾桶、办公桌、软木板、实验室惊吓柜子底部(惊吓后才可拾取)。
- 修复:接待台后面的信格墙原本建在大厅墙外(看不见),已移回墙内。
- 新测试 tests/letters.gd(已加入 run_all.sh);tests/play.gd 支持 ALL_LETTERS=1 验证彩蛋结局。

## v10 进度(用户试玩反馈后的整体修改)
- 墙面文字全部改为"画上去的贴图":scripts/tex_render.gd(把 Control 渲染成图)+ scripts/painted_text.gd(stencil 喷漆 / plate 旧标牌)。大厅标牌、门牌、实验室警示语已替换;只有 EXIT 灯箱还是发光字。
- 删除"本实验室欢迎你的头发";大厅海报改为被涂鸦的米诺地尔广告(scripts/poster.gd),兼做米诺地尔科普。
- 剧情:委托人改为镇长(本人已秃);小女孩"抛硬币定怎么养"是镇上的谣言(序幕附注、接待台剪报、妈妈的来信"我们没抛过硬币,是她自己抛的"、结局"硬币是我自己的")。
- 主动展示:开局自动弹出《水样检测报告》;保险箱打开先弹"获得物品"窗口,关掉后自动打开日记,再触发收音机。
- 日记线索:2025.12.1 指出排污阀在后门旁;2026.3.15 给出抑毛因子-K 用量(100 - 95)。终端不再直接给用量。
- 新玩法:后门旁的排污阀(lab.gd _build_valve),连按 12 次拧紧(UI.qte 新增 verb 参数);失败的巨响会把走开的弟子1号叫回来(boss.loud_noise);必须关阀才能交生发剂。
- 来信:更亮;捡到第一封时提示"应该不止这一封";检测报告结尾提到"镇上很多人给实验室写过信"。
- 假发:金黄色侧分大背头新造型,文案"好眼熟。像某个政治人物";双马尾文案"……Miku?!"(商业发布前建议改,见下)。
- 新测试 tests/valve.gd(排污阀 + 保险箱流程),已加入 run_all.sh。
- 注意:"Miku" 是 Crypton 的角色名,商业发布前建议换成不点名的说法。

## v11 进度
- 接待台:剪报改为普通小镇新闻(《柳湾周报》帽子脱销)。
- 日记新增第一页 2023.11.20:Sarah 受不了博士洗完澡不清理水槽、头发堵下水道(呼应遗言)。
- 来信更显眼:信封放大、自发光呼吸 + 小暖光(scripts/glint.gd);HUD 常驻"✉ 镇民来信 n/5";书桌那封挪到办公室门口地上(从门缝塞进来),厕所那封改为平放在垃圾桶顶上。
- 修女追逐:厕所新增清洁工具柜藏身点(restroom.gd _build_closet)。statue.gd 新状态 LURK(=5):玩家躲起来 → 跟丢,退到大厅厕所门口(LURK_PT)来回踱步;玩家没躲又靠近 2.6m 内 → 继续追;拿到镜子碎片 → 闯进厕所(CHASE),可以刺她。目标提示随之变化。
- 新测试 tests/hide.gd,已加入 run_all.sh(共 9 项)。
