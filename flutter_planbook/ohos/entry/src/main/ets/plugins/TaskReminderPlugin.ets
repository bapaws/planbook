import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@ohos.base';

const CHANNEL = 'com.bapaws.planbook/task_reminder';

/** 计划本任务提醒的鸿蒙 MethodChannel 实现。 */
export default class TaskReminderPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  getUniqueClassName(): string {
    return 'TaskReminderPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(_: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'requestPermission':
        this.requestPermission(result);
        break;
      case 'schedule':
        this.schedule(call, result);
        break;
      case 'cancelMany':
        this.cancelMany(call, result);
        break;
      default:
        result.notImplemented();
    }
  }

  private async requestPermission(result: MethodResult): Promise<void> {
    try {
      let enabled = await notificationManager.isNotificationEnabled();
      if (!enabled) {
        try {
          const context = getContext(this) as common.UIAbilityContext;
          await notificationManager.requestEnableNotification(context);
        } catch (_) {
          // 用户拒绝时继续读取最终状态，由 Dart 侧展示设置引导。
        }
        enabled = await notificationManager.isNotificationEnabled();
      }
      result.success(enabled);
    } catch (error) {
      this.reportError(result, error as BusinessError);
    }
  }

  private async schedule(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const notificationId: number = call.argument('notificationId');
      const title: string = call.argument('title');
      const content: string = call.argument('content');
      const triggerAt: number = call.argument('triggerAt');
      const date = new Date(triggerAt);

      if (notificationId === null || title === null || triggerAt === null ||
        Number.isNaN(date.getTime())) {
        result.error('invalid_arguments', '任务提醒参数不完整', null);
        return;
      }

      const request: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: date.getFullYear(),
          month: date.getMonth() + 1,
          day: date.getDate(),
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds(),
        },
        title: title,
        content: content,
        expiredContent: content,
        notificationId: notificationId,
        groupId: 'planbook_task_alarm',
        slotType: notificationManager.SlotType.SERVICE_INFORMATION,
        tapDismissed: true,
        wantAgent: {
          pkgName: 'com.bapaws.planbook',
          abilityName: 'EntryAbility',
        },
      };

      const reminderId = await reminderAgentManager.publishReminder(request);
      result.success(reminderId);
    } catch (error) {
      this.reportError(result, error as BusinessError);
    }
  }

  private async cancelMany(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const notificationIds: Array<number> = call.argument('notificationIds');
      if (notificationIds === null) {
        result.error('invalid_arguments', '缺少通知 ID 列表', null);
        return;
      }
      const notificationIdSet = new Set<number>(notificationIds);
      const reminders = await reminderAgentManager.getAllValidReminders();
      for (const reminder of reminders) {
        const notificationId = reminder.reminderReq.notificationId;
        if (notificationId !== undefined && notificationIdSet.has(notificationId)) {
          await reminderAgentManager.cancelReminder(reminder.reminderId);
        }
      }
      result.success(null);
    } catch (error) {
      this.reportError(result, error as BusinessError);
    }
  }

  private reportError(result: MethodResult, error: BusinessError): void {
    result.error(error.code?.toString() ?? 'task_reminder_error', error.message, null);
  }
}
