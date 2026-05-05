# 新会话提示词

## 项目背景

二战六边形格战棋，Godot 4.6.2 Steam 版，GDScript。

**项目路径**: `D:\项目\godot\大战略01`
**引擎路径**: `D:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`

## 恢复上下文

按顺序阅读以下文件：

1. **`.opencode.md`** — AI 必须遵守的开发规则（UI/代码/测试/数值/策划等 13 大类）
2. **`docs/SESSION_SUMMARY.md`** — 上一会话进度摘要
3. **`docs/DEVELOPMENT.md`** — 开发文档和第一阶段计划
4. **`docs/DESIGN_0.1.md`** — 完整设计规格书

## 当前状态

第一阶段（主菜单→第一关胜利）核心流程已跑通，但 UI 大部分是代码生成，正在按原型迁移到 `.tscn` 场景文件。

### 已完成的步骤
- 步1: 基础修复（AP=3、Godot 4 API 兼容、测试适配）
- 步2: 主菜单 + SceneManager
- 步3: 国家选择 + 指挥官创建
- 步4: 部署界面
- 步5: 战场 HUD（选中→移动→攻击，HQ 改为部队）
- 步6: 战斗预览 + 战斗报告面板
- 步7: 第一关数据配置（json 加载器）
- 步8: 胜利/失败结算

### 当前待完成

- 主菜单刚迁移到 `.tscn`，其他界面（国家选择/指挥官创建/部署/战场）还是代码生成，需逐步迁移
- 战斗公式已按 DESIGN §4 重写，但数值体验未细调
- 部署 TODO：主菜单正在调样式，后续按流程调整个界面

## 运行测试

```powershell
$godot = "D:\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
# 烟雾测试
Start-Process -FilePath $godot -ArgumentList "--headless --path D:\项目\godot\大战略01 res://tests/test_smoke.tscn --quit" -NoNewWindow -PassThru -Wait
# 全量测试
Start-Process -FilePath $godot -ArgumentList "--headless --path D:\项目\godot\大战略01 res://tests/test_full.tscn --quit" -NoNewWindow -PassThru -Wait
```

## 调试方法

```powershell
# 启动游戏（编辑器会打开窗口）
editor.run
# 查看输出
editor.debug_output
# 停止
editor.stop
```

## 关键约定

- **不创建新文件除非被要求**（尤其是文档类）
- **不提交代码除非被明确要求**
- **修改 DESIGN_0.1.md 前先问用户**
- **删除文件前先问用户**
- **开工新步骤前先问用户**
