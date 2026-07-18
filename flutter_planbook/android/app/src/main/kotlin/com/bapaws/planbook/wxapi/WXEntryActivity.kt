package com.bapaws.planbook.wxapi

import com.jarvan.fluwx.wxapi.FluwxWXEntryActivity

/**
 * 微信登录 / 分享回调入口。
 * 必须位于应用包名 + .wxapi 包下，并在 AndroidManifest.xml 中注册 exported="true"。
 */
class WXEntryActivity : FluwxWXEntryActivity()
