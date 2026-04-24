# Auto Sound Interval Detection for Personal Use

这是一个面向个人使用的纯 `Praat` 小项目，用于批量检测音频中的：

`键盘点击 -> 说话开始`

并输出两者之间的时间间隔。

这个版本只保留当前可用的纯 `Praat` 工作流，不包含之前的 Python 原型，也不包含混合 `Whisper` 方案，适合直接上传到 Git 或发给朋友使用。

## 适用场景

适合这类录音：

- 有轻微背景噪声
- 键盘点击短促且清晰
- 说话开始相对明确
- 一个音频里有多次 `click -> think -> answer` 试次

## 项目文件

- [detect_intervals.praat](/Users/tomchuean_/Projects/Auto_Sound_Interval_Detection/auto-sound-interval-detection-praat-for-personal-use/detect_intervals.praat)：主检测脚本
- [run_praat_batch.sh](/Users/tomchuean_/Projects/Auto_Sound_Interval_Detection/auto-sound-interval-detection-praat-for-personal-use/run_praat_batch.sh)：启动脚本，封装了一组默认参数
- [test_wav.wav](/Users/tomchuean_/Projects/Auto_Sound_Interval_Detection/auto-sound-interval-detection-praat-for-personal-use/test_wav.wav)：示例音频

## 工作原理

脚本会对每个音频做两轮分段：

1. 用更严格的阈值检测类似键盘 click 的短促瞬态声音。
2. 用更宽松的阈值检测可能的语音区间。

之后，脚本会把每个有效 click 和后续的语音候选做匹配，并通过一些启发式规则过滤明显不合理的 onset，例如：

- click 本身被误识别为语音
- click 后立刻出现的短促非语言 burst
- 太短、不稳定的候选段
- onset 过早但后续支撑不足的片段

当前版本仍然是启发式方案，不保证所有 trial 都完全准确，但在轻度噪声、click 清晰的录音上已经具备可用性。

## 环境要求

- macOS
- 已安装 Praat
- 默认 Praat 路径为 `/Applications/Praat.app`

## 用法

### 处理单个音频

```bash
./run_praat_batch.sh test_wav.wav praat_results.csv
```

### 处理整个文件夹

```bash
./run_praat_batch.sh /path/to/audio_folder results.csv "*.wav"
```

## 输出格式

脚本会输出一个 CSV，字段如下：

- `file`：音频文件名
- `trial_index`：试次编号
- `click_time_s`：click 时间，单位秒
- `speech_onset_s`：检测到的说话起点，单位秒
- `interval_s`：二者间隔，单位秒
- `status`：状态

默认只输出成功匹配的结果。

## 说明

- 当前推荐直接从 `run_praat_batch.sh` 开始使用。
- 如果要调参数，直接修改 [detect_intervals.praat](/Users/tomchuean_/Projects/Auto_Sound_Interval_Detection/auto-sound-interval-detection-praat-for-personal-use/detect_intervals.praat) 顶部的参数表单即可。
- 这个项目主要用于个人研究或小范围共享，不是一个通用的高鲁棒性语音检测工具。
