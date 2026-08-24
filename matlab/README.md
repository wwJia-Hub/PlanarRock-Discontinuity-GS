# Planar Rock Discontinuity — 岩石结构面识别与分组

基于三角网格（PLY）的**岩体结构面（不连续面）自动识别、产状提取与分组** MATLAB 工具箱。
从摄影测量 / 激光扫描得到的岩体表面网格出发，自动分割出候选结构面区域，
再用鲸鱼优化算法（WOA）结合轮廓系数确定最优分组数，得到主要结构面组及其倾向/倾角。

> 界面与算法流程图、极点图、玫瑰图等详见下方说明。

---

## ✨ 主要功能

- **网格读取**：支持 ASCII / 二进制（little & big endian）PLY，多边形自动三角化。
- **网格平滑**：拉普拉斯平滑，消除扫描噪声对法线估计的影响。
- **结构面候选区域分割**：基于法线夹角的区域生长，将网格分割为若干平面区域。
- **结构面分组**：以区域平均法线为特征，用 WOA 聚类 + 轮廓系数自动确定最优分组数 K。
- **产状输出**：每组结构面的倾向（Azimuth）与倾角（Dip）。
- **可视化**：三维着色分组图、极点图、玫瑰图、南丁格尔玫瑰图、收敛曲线。
- **图形界面（GUI）**：`DiscontinuityAnalyzer` 一键式交互操作与结果导出。

## 🚀 快速开始

### 环境要求

- MATLAB **R2018b** 及以上（使用 GUI 时）。
- 仅使用核心算法（`main.m`）：MATLAB **R2016b** 及以上即可。
- 无需任何第三方工具箱。

### 方式一：图形界面

在 MATLAB 命令行运行：

```matlab
DiscontinuityAnalyzer
```

然后：选择 PLY 文件 → 设置参数（或保持默认）→ 点击「运行分析」→ 查看分组结果表，
按需勾选要绘制的图，最后「导出结果」保存 `.mat` 或 `.csv`。

### 方式二：脚本（`main.m`）

直接运行顶层 `main.m`，或修改其中的参数后运行：

```matlab
params = struct( ...
    'a0_deg', 10, 'b0_deg', 10, 'min_component_size', 85, ...
    'SearchAgents_no', 300, 'Max_iteration', 500, 'k_min', 2, 'k_max', 8);

result = runDiscontinuityAnalysis('data/example_rock_slope.ply', params);
```

`result` 中包含分组数、各组倾向/倾角、分组标签、面索引等完整信息。

### 示例数据

仓库附带合成示例 `data/example_rock_slope.ply`（3 组结构面，共 12 个分离平面小块），
可用 `data/make_example.m` 重新生成。示例网格较小，若使用默认 `min_component_size=85`
可直接运行；对更小的自定义网格，请适当调低该参数。

## 🧭 算法流程

```
PLY 网格
   │  readMesh_ply
   ▼
顶点 / 三角面
   │  meshSmoothing（可选）
   ▼
面法线  meshFaceNormals
   │
   ▼
区域生长分割  segmentMesh  ──►  候选结构面区域 + 区域平均法线
   │
   ▼
WOA 聚类 + 轮廓系数选 K  ──────►  结构面分组 + 各组倾向/倾角
   │
   ▼
可视化 / 结果导出
```

**核心算法要点**

- **区域生长**：相邻三角面法线夹角小于阈值 `a0` 视为同一平面区域；区域间法线夹角
  小于阈值 `b0` 时合并；面数小于 `min_component_size` 的区域被丢弃。
- **分组**：以区域平均法向量为样本，采用 [鲸鱼优化算法（WOA）](https://doi.org/10.1016/j.advengsoft.2016.01.008)
  最小化加权 SSA 距离 `d = 1 - (nᵢ·cⱼ)²`，用轮廓系数在 K ∈ [k_min, k_max] 内选取最优分组数。

## 📁 目录结构

```
.
├── DiscontinuityAnalyzer.m       # GUI 主界面（入口）
├── main.m                        # 脚本入口（非 GUI）
├── runDiscontinuityAnalysis.m    # 核心流程引擎
├── startup.m                     # 路径初始化（加入所有子目录）
├── data/
│   ├── example_rock_slope.ply    # 合成示例网格
│   └── make_example.m            # 示例生成脚本
├── src/
│   ├── io/          readMesh_ply.m
│   ├── mesh/        meshSmoothing / meshFaceNormals / meshFaceAreas / findVertexSharingFaces / faceNormals
│   ├── segmentation/ segmentMesh.m
│   ├── clustering/  WOA / initialization / fitness / dip_distance / silhouetteCoefficient /
│   │                DBSCAN / computeSAADistanceMatrix / discontinuity_kmeans
│   └── viz/         plotPoleFigure / plotPoleRose / plotpoleNDGER / visualizeClusters /
│                    visualizeClusters2 / normal_to_dip / plot_convergence_curve / plotPoleFigureVectors
└── experimental/                 # 实验性/变体代码（详见其内 README）
```

## ⚙️ 参数说明

| 参数 | 默认 | 含义 |
|------|------|------|
| `a0_deg` | 10 | 相邻三角面法线夹角阈值（度），控制平面区域的严格程度 |
| `b0_deg` | 10 | 区域（簇）间法线夹角阈值（度），控制区域合并 |
| `min_component_size` | 85 | 最小结构面区域面数，小于该值的碎片区域被丢弃 |
| `smooth` / `smooth_iterations` / `smooth_lambda` | true / 15 / 0.3 | 拉普拉斯平滑开关与参数 |
| `SearchAgents_no` | 300 | WOA 种群（鲸鱼）数量 |
| `Max_iteration` | 500 | WOA 最大迭代次数 |
| `k_min` / `k_max` | 2 / 8 | 结构面分组数的搜索范围 |

## 📄 输入数据格式

输入为三角网格 PLY 文件，需包含：

- 顶点：`x` / `y` / `z`（float）
- 面：`vertex_indices`（list，0-based 或 1-based 自动处理；多边形自动扇形三角化）

## 🔬 引用与致谢

- 鲸鱼优化算法：[Mirjalili S., Lewis A. *The Whale Optimization Algorithm*, Advances in Engineering Software, 2016.](https://doi.org/10.1016/j.advengsoft.2016.01.008)
- 若本项目对你的研究有帮助，欢迎在论文中引用本仓库（https://github.com/wwJia-Hub/PlanarRock-Discontinuity-GS）。

## 📝 许可证

本项目基于 [MIT License](LICENSE) 开源。© 2026 wwJia
