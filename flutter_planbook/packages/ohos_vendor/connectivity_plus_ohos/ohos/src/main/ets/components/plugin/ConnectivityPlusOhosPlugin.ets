import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult,
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import connection from '@ohos.net.connection';
import { BusinessError } from '@ohos.base';
import EventChannel, { StreamHandler, EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';


/** ConnectivityPlusOhosPlugin **/
export default class ConnectivityPlusOhosPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private receiver: ConnectivityBroadcastReceiver | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "ConnectivityPlusOhosPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "dev.fluttercommunity.plus/connectivity");
    this.channel.setMethodCallHandler(this)
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), "dev.fluttercommunity.plus/connectivity_status");
    this.receiver = new ConnectivityBroadcastReceiver();
    this.eventChannel.setStreamHandler(this.receiver!);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    if (this.eventChannel != null) {
      this.eventChannel.setStreamHandler(null);
    }
    this.receiver?.unregister();
    this.receiver = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    if (call.method == "check") {
      let netHandle = await connection.getDefaultNetSync();
      result.success(await ConnectivityPlusOhosPlugin.getNetBearType(netHandle));
    } else {
      result.notImplemented()
    }
  }


  static async getNetBearType(netHandle: connection.NetHandle): Promise<string> {
    let data = await connection.getNetCapabilitiesSync(netHandle);
    let bearerTypes: Set<connection.NetBearType> = new Set(data.bearerTypes);
    let bearerTypesNum = Array.from(bearerTypes.values());
    let netBearType = 'none';
    for (let item of bearerTypesNum) {
      if (item == connection.NetBearType.BEARER_CELLULAR) {
        netBearType = 'mobile';
      } else if (item == connection.NetBearType.BEARER_WIFI) {
        netBearType = 'wifi';
      } else if (item == connection.NetBearType.BEARER_ETHERNET) {
        netBearType = 'ethernet';
      }
    }
    return netBearType;
  }
}

class ConnectivityBroadcastReceiver implements StreamHandler {
  onCancel(args: ESObject): void {
    this.events = null;
    this.unregister();
  }

  private events: EventSink | null = null;
  private connection: connection.NetConnection | null = null;

  unregister(): void {
    this.connection?.unregister(() => {
    });
    this.connection = null;
  }

  register(): void {
    let netSpecifier: connection.NetSpecifier = {
      netCapabilities: {
        bearerTypes: [connection.NetBearType.BEARER_CELLULAR, connection.NetBearType.BEARER_WIFI, connection.NetBearType.BEARER_ETHERNET],
        networkCap: [],
      },
    };

    this.connection = connection.createNetConnection(netSpecifier, 0);

    this.connection?.register((err: BusinessError, data: void) => {
    });

    this.connection?.on('netAvailable', ((data: connection.NetHandle) => {
      ConnectivityPlusOhosPlugin.getNetBearType(data).then((value) => {
        this.events?.success(value);
      });
    }));

    this.connection?.on('netUnavailable', ((data: void) => {
      this.events?.success('none');
    }));

    this.connection?.on('netLost', ((data: connection.NetHandle) => {
      this.events?.success('none');
    }));
  }

  onListen(args: ESObject, events: EventSink) {
    this.events = events;
    this.register();
  }
}