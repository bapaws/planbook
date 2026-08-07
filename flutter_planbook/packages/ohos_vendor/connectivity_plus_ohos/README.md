# connectivity_plus_ohos

[![pub package](https://img.shields.io/pub/v/connectivity_plus_ohos.svg)](https://pub.dartlang.org/packages/connectivity_plus_ohos) [![GitHub stars](https://img.shields.io/github/stars/harmonycandies/connectivity_plus_ohos)](https://github.com/harmonycandies/connectivity_plus_ohos/stargazers) [![GitHub forks](https://img.shields.io/github/forks/harmonycandies/connectivity_plus_ohos)](https://github.com/harmonycandies/connectivity_plus_ohos/network) [![GitHub license](https://img.shields.io/github/license/harmonycandies/connectivity_plus_ohos)](https://github.com/harmonycandies/connectivity_plus_ohos/blob/master/LICENSE) [![GitHub issues](https://img.shields.io/github/issues/harmonycandies/connectivity_plus_ohos)](https://github.com/harmonycandies/connectivity_plus_ohos/issues) <a target="_blank" href="https://qm.qq.com/q/ajfsyk2RcA"><img border="0" src="https://pub.idqqimg.com/wpa/images/group.png" alt="harmony-candies" title="harmony-candies"></a>

This plugin allows Flutter apps to discover network connectivity types that can be used on OpenHarmony.

The OpenHarmony implementation of [`connectivity_plus`][1].

[`connectivity_plus`][1] 在 OpenHarmony 平台的实现。


# 使用

```yaml
dependencies:
  connectivity_plus: 5.0.2
  connectivity_plus_ohos: any
```

在你的项目的 `module.json5` 文件中增加以下权限设置。

```json
    requestPermissions: [
      {"name" :  "ohos.permission.INTERNET"},
      {"name" :  "ohos.permission.GET_NETWORK_INFO"},
    ],
```


 [1]: https://pub.dev/packages/connectivity_plus

