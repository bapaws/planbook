/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { bundleManager } from '@kit.AbilityKit';

/** AppSettingsPlugin **/
export default class AppSettingsPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "AppSettingsPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.spencerccf.app_settings/methods");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "openSettings") {
      this.handleOpenSettings(call, result);
    } else if (call.method == "openSettingsPanel") {
      this.handleOpenSettingsPanel(call, result);
    } else {
      result.notImplemented();
    }
  }

  /**
   * Handle the 'openSettings' method call.
   */
  private handleOpenSettings(call: MethodCall, result: MethodResult): void {
    switch (call.argument("type")) {
      case "wifi":
        this.openSettings("wifi_entry", result);
        break;
      case "nfc":
        this.openSettings("nfc_settings", result);
        break;
      case "location":
        this.openSettings("location_manager_settings", result);
        break;
      case "bluetooth":
        this.openSettings("bluetooth_entry", result);
        break;
      case "notification":
        this.openSettings("systemui_notification_settings", result);
        break;
      case "display":
        this.openSettings("display_settings", result);
        break;
      case "sound":
        this.openSettings("volume_settings", result);
        break;
      case "date":
        this.openSettings("date_and_time", result);
        break;
      case "internalStorage":
        this.openSettings("storage_settings", result);
        break;
      case "developer":
        this.openSettings("developer_options_settings", result);
        break;
      case "security":
        this.openSettings("privacy_settings", result);
        break;
      case "accessibility":
        this.openSettings("accessibility_feature", result);
        break;
      case "hotspot":
        this.openSettings("hotspot_data_settings", result);
        break;
      case "settings":
        this.openAppSettings("application_info_entry", result);
        break;
      case "device":
        this.openSettings("about_device", result);
        break;
      case "batteryOptimization":
        this.openSettings("battery", result);
        break;
      default:
        result.notImplemented();
    }
  }

  /**
   * Open the settings panel for the given url.
   */
  private openSettings(url: string, result: MethodResult): void {
    let want: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: url,
    }
    let context = getContext(this) as common.UIAbilityContext;
    context.startAbility(want).then(() => {
      console.info('Start settings ability successfully.');
    }).catch((err: BusinessError) => {
      console.info(`Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
    });
    result.success(null);
  }

  /**
   * Open the application settings.
   */
  private openAppSettings(url: string, result: MethodResult) {
    let bundleName = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).name;
    let wantInfo: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: url,
      parameters: {
        pushParams: bundleName
      }
    };
    let context = getContext(this) as common.UIAbilityContext;
    context.startAbility(wantInfo).then(() => {
      console.info('Start settings ability successfully.');
    }).catch((err: BusinessError) => {
      console.error(`Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
    });
    result.success(null);
  }

  /**
   * Handle the 'openSettingsPanel' method call.
   */
  private handleOpenSettingsPanel(call: MethodCall, result: MethodResult) {
    let context = getContext(this) as common.UIAbilityContext;

    switch (call.argument("type")) {
      case "wifi":
        context.startAbility({
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: 'wifi_entry',
        });
        break;
      case "nfc":
        context.startAbility({
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: 'nfc_settings',
        });
        break;
      case "internetConnectivity":
        context.startAbility({
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: 'mobile_network_entry',
        });
        break;
      case "volume":
        context.startAbility({
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: 'volume_settings',
        });
        break;
      default:
        result.notImplemented();
    }
  }

}