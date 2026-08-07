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
import systemDateTime from '@ohos.systemDateTime';
import { List } from '@kit.ArkTS';
import { i18n } from '@kit.LocalizationKit';

/** FlutterTimezoneOhosPlugin **/
export default class FlutterTimezoneOhosPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private result: MethodResult | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "FlutterTimezoneOhosPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_timezone_ohos");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  getLocalTimezone(): String {
    let sysZone = systemDateTime.getTimezoneSync();
    let timezone = i18n.getTimeZone(sysZone);
    return timezone.getID();
  }

  getAvailableTimezones() {
    let zoneList: List<String> = new List();
    let arrayList = i18n.TimeZone.getAvailableIDs();
    arrayList.forEach(value => {
      zoneList.add(value);
    });
    // for (let i =0;i<arrayList.length;i++){
    //   zoneList.add(arrayList[i]);
    // }
    this.result?.success(zoneList);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.result = result;
    if (call.method == "getLocalTimezone") {
      result.success(this.getLocalTimezone());
    } else if (call.method == "getAvailableTimezones") {
      this.getAvailableTimezones();
    } else {
      result.notImplemented()
    }
  }
}