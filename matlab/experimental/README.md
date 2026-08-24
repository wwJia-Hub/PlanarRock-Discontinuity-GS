# experimental/ — 实验性 / 变体代码

本目录保存了开发过程中产生的、**未纳入主流程**的实验性代码与变体实现，
供参考与回溯，不保证与当前 `src/` 主流程完全一致。

| 文件 | 说明 |
|------|------|
| `Main.m` | 早期主脚本（含大量被注释掉的实验片段），已被顶层 `main.m` 取代 |
| `main_batch.m` | 批量参数扫描脚本（遍历 a0/b0/min_component_size 组合） |
| `run_clustering_once.m` | 单次运行的旧封装，已被 `runDiscontinuityAnalysis.m` 取代 |
| `compute.m` | 面积加权版区域生长（`segmentMesh.m` 为计数加权版） |
| `compute2.m` | 面积加权版区域生长的另一实现 |
| `compute_low.m` | 未完成的精简版 |
| `test.m` | 早期测试脚本 |
| `clustering.m` | 基于 DBSCAN 的二次聚类脚本（依赖未定义变量，供参考） |
| `PlotClusterinResult.m` | DBSCAN 聚类结果绘图辅助 |
| `computeAdjacencyList.m` | 基于共边的面邻接表（主流程用共顶点邻接） |
| `partition_mesh_ply.m` | 大网格谱划分工具（用于并行处理实验） |
| `Main_gpu.m` | GPU 加速实验（依赖未实现的 GPU 版网格函数） |
| `Main_parpool.m` | 并行池分块实验 |
| `ensurePool.m` | 并行池管理辅助 |
| `meshSmoothing2.m` | `meshSmoothing.m` 的重复副本 |
| `fitness2.m` | 未加权版目标函数 |
| `NRBO.m` | Newton-Raphson 优化器（替代 WOA 的备选，`initialization` 签名与主流程不一致，未接入） |
| `SearchRule.m` | NRBO 的搜索规则组件（仅被 NRBO 调用） |
| `*.asv` | MATLAB 自动备份文件 |
