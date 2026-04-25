# Auto Sound Interval Detection Praat Personal Use

这是一个面向个人研究使用的 Praat 批处理项目，用于从录音中提取：

`键盘点击 -> 说话开始`

脚本会输出每个 trial 的 click onset、speech onset，以及两者之间的间隔。当前主版本来自测试效果较好的 `test_3.praat` 思路，并改成了可处理单个音频或整个文件夹的批处理脚本。

## 当前版本

主检测逻辑是纯 Praat amplitude 阈值方案：

1. 读取音频后计算全局最大振幅。
2. 用相对振幅阈值检测短促 click，并向前回溯到 click onset。
3. 从 click 后 1 秒开始搜索语音。
4. 用固定长度窗口检查持续振幅命中率，找到 speech onset。
5. 输出所有 click 对应的结果；没有找到语音时保留 `speech_not_found` 行，方便人工检查。

这个版本不依赖 Python，也不使用之前实验过的 spectrum/template/VAD 原型。

## 适用录音

适合这类材料：

- 每个 trial 有一个清晰的键盘点击或按键声。
- 说话通常出现在 click 后 1 到 10 秒内。
- 音频整体音量相对稳定。
- 背景噪声不强，或者至少低于 click 与语音主体。

如果录音中 click 很弱、说话音量变化很大，或者受试者在 click 后 1 秒内已经开始说话，需要调整参数。

## 文件

- `detect_intervals.praat`：主检测脚本，保留 `test_3` 的核心检测逻辑，并支持批处理。
- `run_praat_batch.sh`：macOS 启动脚本，封装默认参数。
- `test_wav.wav`：示例音频。

## 环境要求

- macOS
- Praat.app 安装在 `/Applications/Praat.app`
- zsh

## 用法

先进入项目文件夹：

```bash
cd /Users/tomchuean_/Projects/auto-sound-interval-detection-praat-for-personal-use/auto-sound-interval-detection-praat-personal-use
```

处理单个音频：

```bash
./run_praat_batch.sh test_wav.wav results.csv
```

处理整个文件夹：

```bash
./run_praat_batch.sh /path/to/wavs results.csv "*.wav"
```

第三个参数是文件匹配规则；如果不传，默认处理 `*.wav`。

## 输出格式

CSV 字段：

- `sound`：音频文件名
- `trial`：trial 编号
- `click_onset`：click onset，单位秒
- `speech_onset`：speech onset，单位秒；未找到时为 `NA`
- `interval`：speech onset 减 click onset，单位秒；未找到时为 `NA`
- `status`：`OK`、`speech_not_found`、`click_not_found` 或 `zero_amplitude`

时间是每个音频自己的秒数时间轴，从该音频开头开始计算。

## 默认参数

`run_praat_batch.sh` 使用以下参数：

| 参数 | 默认值 | 作用 |
| --- | ---: | --- |
| `Time_step` | `0.001` | 扫描步长，单位秒 |
| `Click_relative_threshold` | `0.45` | click 检测阈值，占全局最大振幅的比例 |
| `Click_onset_relative_threshold` | `0.08` | click onset 回溯阈值，占全局最大振幅的比例 |
| `Min_click_gap` | `0.800` | 两个 click 之间的最小间隔 |
| `Speech_window_start` | `1.0` | click 后多久开始找语音 |
| `Speech_window_end` | `10.000` | click 后最晚找多久 |
| `Guard_before_next_click` | `0.100` | 下一个 click 前预留的保护间隔 |
| `Speech_threshold` | `0.015` | 语音振幅绝对阈值 |
| `Min_speech_duration` | `0.120` | 判定语音的最短持续窗口 |
| `Min_speech_hit_ratio` | `0.70` | 窗口内超过语音阈值的最低比例 |

## 调参建议

- 漏掉 click：降低 `Click_relative_threshold`，例如从 `0.45` 调到 `0.35`。
- 把非 click 当作 click：提高 `Click_relative_threshold` 或增大 `Min_click_gap`。
- 语音 onset 偏晚：降低 `Speech_threshold` 或 `Min_speech_hit_ratio`。
- 背景噪声被当成语音：提高 `Speech_threshold` 或 `Min_speech_hit_ratio`。
- 受试者很快开始回答：降低 `Speech_window_start`，例如改成 `0.5`。

## 注意

这是为个人录音材料整理的启发式工具，不是通用语音活动检测器。建议每次换受试者或录音设备后，抽查几条结果，并根据上面的参数做小范围调整。
