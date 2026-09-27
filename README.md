# 模块开发模板

基于 `build.sh` + `push.sh` + `.buildrc` 的模块开发脚手架。

## 文件说明

| 文件 | 作用 |
|---|---|
| `build.sh` | 打包模块为 zip |
| `push.sh` | 把源码推到已装模块目录（热更新） |
| `.buildrc` | 项目配置 |
| `module.prop` | 模块信息（必需） |

## 快速开始

### 1. 准备项目

```
MyModule/
├── module.prop
├── customize.sh
├── post-fs-data.sh
├── service.sh
├── uninstall.sh
├── bin/
├── webroot/
├── build.sh
├── push.sh
└── .buildrc
```

### 2. 改 `.buildrc`

```sh
DIST_NAME="dist"
PACK_FILES="
module.prop
customize.sh
post-fs-data.sh
service.sh
uninstall.sh
"
PUSH_FILES="$PACK_FILES"
VARIANTS=""
```

### 3. 打包

```sh
bash build.sh
```

方向键选择「打包模块」，生成 `dist/<id>-default-<时间>.zip`。

### 4. 推到手机测试

```sh
su -c "bash push.sh"
```

方向键选择「推送修改到已装模块」，多选要推的文件，回车确认。

## 变体

如果模块需要多个变体（比如不同品牌）：

```sh
VARIANTS="
hyperos:xiaomi:payload/xxx.zip
oneplus:oneplus:payload/yyy.zip
"
```

`build.sh` 会为每个变体生成一个 zip。

## 注意事项

- `build.sh` / `push.sh` 需要 `bash`，Termux 里 `pkg install bash`
- `push.sh` 需要 root，用 `su -c` 跑
- `module.prop` 必须包含 `id=`，否则脚本会报错
- `PACK_FILES` / `PUSH_FILES` 留空会自动扫描，但建议显式列出

## 协议

本项目采用 [MIT License](LICENSE) 开源。

## 声明

- 本模板由 AI 辅助生成，仅供学习与开发参考
- 使用前请自行检查脚本逻辑，风险自负
- 风格参考：幸せな小さな雑魚 https://www.coolapk.com/u/31946549