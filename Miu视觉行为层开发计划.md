# Miu 视觉层与行为层开发计划

## 目标

先开发 Miu 的视觉层和行为层，让它更像一只有分寸、温顺、可爱的蓝双布偶猫。轻提醒系统放到最后开发。

核心体验：

- 工作时安静陪伴，不遮挡窗口。
- 休闲时可以散步、探头、撒娇。
- 夜晚按北京时间睡觉休息。
- 用户互动时有轻量反馈。

## Phase 1：视觉动作扩展

新增动作：

- `loaf`：香箱趴，工作陪伴。
- `sleep`：蜷起来睡觉。
- `wake`：醒来伸懒腰。
- `stretch`：伸展。
- `peek`：从屏幕边缘探头。
- `groom`：舔爪洗脸。
- `purr`：眯眼呼噜。
- `sit-watch`：坐着看用户工作。
- `edge-walk`：沿屏幕或窗口边缘慢走。
- `celebrate`：任务完成后小幅开心跳。
- `comfort`：任务失败后歪头陪伴。

优先级：

1. `loaf`
2. `sleep`
3. `wake` / `stretch`
4. `peek`
5. `edge-walk`
6. `groom` / `purr`
7. `celebrate` / `comfort`

## Phase 2：核心状态机

建立 Miu 的基础模式：

```ts
type PetMode =
  | 'work'
  | 'leisure'
  | 'night'
  | 'busy'
  | 'idle'
  | 'success'
  | 'failed'
```

行为映射：

- `work`：`loaf` / `sit-watch` / `purr`，低频动画。
- `busy`：`waiting` / `sit-watch`。
- `idle`：`peek` / `groom` / `edge-walk`。
- `leisure`：`edge-walk` / `waving` / `jumping`。
- `night`：`sleep`。
- `success`：`celebrate`。
- `failed`：`comfort`。

## Phase 3：窗口避让

目标：Miu 不挡住用户打开的软件窗口。

规则：

- 工作模式：只待在安全角落或屏幕边缘。
- 前台窗口占屏幕较大时：Miu 自动缩小并贴边。
- 全屏应用：Miu 进入极简陪坐、睡觉或隐藏。
- 鼠标靠近：Miu 轻微让开。
- 用户正在输入：不横穿屏幕。
- 休闲模式：可以沿窗口外边缘走，但不进入内容中心。

区域模型：

```ts
type PetZone =
  | 'bottom-right'
  | 'bottom-left'
  | 'top-right'
  | 'top-left'
  | 'window-edge'
  | 'desktop-free'
```

## Phase 4：北京时间昼夜节律

默认时间规则：

- `07:30 - 09:00`：`wake` / `stretch`
- `09:00 - 18:30`：工作行为为主
- `18:30 - 22:30`：休闲行为为主
- `22:30 - 23:30`：困倦、洗脸、慢速 idle
- `23:30 - 07:30`：睡觉

配置草案：

```ts
type PetDayNightConfig = {
  timezone: 'Asia/Shanghai'
  sleepStart: '23:30'
  wakeTime: '07:30'
}
```

## Phase 5：基础互动

互动形式：

- 单击：抬头 / 眨眼。
- 双击：挥爪。
- 悬停：看向鼠标。
- 拖动：允许用户把 Miu 放到指定角落。
- 右键：打开简单菜单。
- 长时间无操作：Miu 自己散步、趴下或睡一会。

原则：

- 不抢焦点。
- 不打断输入。
- 不主动覆盖主要窗口。

## Phase 6：设置面板

先只做行为相关设置：

- 工作模式：安静 / 标准 / 活泼。
- 休闲模式：是否允许散步。
- 夜间睡觉：开关。
- 默认位置：四角选择。
- 自动避让窗口：开关。
- 动画强度：低 / 中 / 高。

轻提醒系统只保留入口或占位，不实际开发。

## Phase 7：轻提醒系统

最后开发：

- 每隔一小时休息提醒。
- 定期喝水提醒。
- 久坐提醒。
- 睡觉提醒。
- 自定义提醒。

提醒复用前面稳定动作：

- 休息：`stretch`
- 喝水：`waving`
- 久坐：`edge-walk` / `stretch`
- 睡觉：`sleep`

## 推荐开发顺序

1. 补动作素材：`loaf`、`sleep`、`stretch`、`peek`。
2. 做状态机：`work` / `leisure` / `night`。
3. 做位置策略：贴边、不挡窗口。
4. 做北京时间昼夜切换。
5. 做基础点击互动。
6. 做设置面板。
7. 最后做轻提醒系统。

## 一句话原则

先让 Miu 有生命，再让 Miu 有功能。
