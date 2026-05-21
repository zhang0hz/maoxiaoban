# 猫小伴动作资产命名规范

## 目录约定

- 正式运行帧放在 `frames/<action-id>/`。
- 单帧命名使用两位数字：`00.png`、`01.png`、`02.png`。
- 生成源图放在 `sources/`，预览 GIF 放在 `gifs/`。如果某个动作只有整理后的运行帧，manifest 中的 `source` 可以指向 `frames/<action-id>`，`gif` 可以为 `null`。
- QA 产物放在 `qa/`，不要被运行时代码直接引用。

## 动作 ID

- 使用小写 kebab-case，例如 `walk-right`、`ear-twitch`。
- 带方向的动作必须显式写方向：`walk-left`、`walk-right`。
- 微表情使用动作本身命名，不并入主 idle 名称：`blink`、`ear-twitch`、`tail-sway`。
- 过渡动作保持语义名称：`wake`、`stretch`、`groom`、`yawn`。

## Manifest 字段

每个正式动作至少记录：

- `id`：运行时动作名。
- `frames`：帧数。
- `mode`：主要使用场景。
- `purpose`：一句话说明动作职责。
- `status`：正式使用写 `formal`，试验保留写 `experimental`，旧素材写 `deprecated`。
- `runtimeUse`：是否由当前 macOS runner 直接使用，以及使用位置。

## 清理原则

- 不直接删除旧素材，先在 manifest 或 `formal-assets.json` 标注 `deprecated`。
- 新动作进入运行时前必须通过颜色审计和 smoke test。
- 行为代码只能引用 `frames/` 中存在的动作，缺失动作必须有明确 fallback。
