# Paper Notebook

复用 Jotbook 的独立 Flutter 本子组件，包含封面开合、纸张折页和内页样式。

来源：`jotbook/packages/paper_notebook`，基准提交 `de0b5136e6713b5c28f0fd3586c6f985ec645c5c`。
以本地包方式纳入，避免构建依赖开发者机器上的相邻工程。组件源码保持原样，后续修复可与 Jotbook 同步。
测试中旧的默认圆角和色板断言已对齐组件现状：A4 外角 22、A5 外角 16，不同封面可共享默认颜色。

封面图片来源见 `assets/covers/CREDITS.md`。
