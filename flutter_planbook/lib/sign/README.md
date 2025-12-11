# 登录功能说明

## 功能概述

本项目实现了完整的用户认证系统，包括：

1. **欢迎页面** - 应用启动页面，展示应用介绍
2. **验证码登录页面** - 手机验证码登录功能
3. **密码登录页面** - 手机号密码登录功能
4. **注册页面** - 新用户注册功能
5. **忘记密码页面** - 密码重置功能

## 技术实现

### 后端服务

- 使用 **Supabase** 作为后端服务
- 支持手机验证码认证
- 支持手机号密码认证
- 支持密码重置功能

### 前端架构

- 使用 **BLoC/Cubit** 进行状态管理
- 使用 **AutoRoute** 进行路由管理
- 使用 **Flutter Localizations** 进行国际化

## 页面说明

### 1. 欢迎页面 (SignWelcomePage)

- 位置：`lib/sign/welcome/view/sign_welcome_page.dart`
- 功能：展示应用介绍，提供验证码登录、密码登录和注册入口
- 样式：参考图片中的第一个屏幕

### 2. 验证码登录页面 (SignInCodePage)

- 位置：`lib/sign/in/view/sign_in_code_page.dart`
- 功能：
  - 手机号输入
  - 验证码发送和输入
  - 表单验证
  - 自动注册（首次使用手机号登录）
  - 切换到密码登录的链接
- 状态管理：`lib/sign/in/cubit/sign_in_cubit.dart`

### 3. 密码登录页面 (SignInPasswordPage)

- 位置：`lib/sign/in/view/sign_in_password_page.dart`
- 功能：
  - 手机号输入
  - 密码输入（支持可见性切换）
  - 表单验证
  - 切换到验证码登录的链接
- 状态管理：`lib/sign/in/cubit/sign_in_cubit.dart`

### 4. 注册页面 (SignUpPage)

- 位置：`lib/sign/up/view/sign_up_page.dart`
- 功能：
  - 姓名、邮箱、密码、确认密码输入
  - 表单验证
  - 条款同意选项
  - 登录页面链接
- 状态管理：`lib/sign/up/cubit/sign_up_cubit.dart`

### 5. 忘记密码页面 (SignPasswordPage)

- 位置：`lib/sign/password/view/sign_password_page.dart`
- 功能：
  - 邮箱输入
  - 发送重置密码链接
  - 返回登录页面
- 状态管理：`lib/sign/password/cubit/sign_password_cubit.dart`

## 通用组件

### 1. SignPageWrapper

- 位置：`lib/core/view/sign_page_wrapper.dart`
- 功能：提供统一的页面布局，包括背景、渐变遮罩、白色卡片

### 2. SignInputField

- 位置：`lib/core/view/sign_input_field.dart`
- 功能：自定义输入框组件，支持验证、图标等

### 3. SignButton

- 位置：`lib/core/view/sign_button.dart`
- 功能：自定义按钮组件，支持加载状态、轮廓样式等

## 路由配置

路由配置在 `lib/app/app_router.dart` 中：

```dart
AutoRoute(page: SignWelcomeRoute.page, initial: true),
AutoRoute(page: SignInCodeRoute.page),
AutoRoute(page: SignInPasswordRoute.page),
AutoRoute(page: SignUpRoute.page),
AutoRoute(page: SignPasswordRoute.page),
```

## 国际化

支持中文和英文，文本配置在：

- `lib/l10n/arb/app_zh.arb` - 中文
- `lib/l10n/arb/app_en.arb` - 英文

## 使用方法

1. 启动应用，会显示欢迎页面
2. 在欢迎页面可以选择：
   - **验证码登录**：适合新用户或忘记密码的用户
   - **密码登录**：适合已有账号的用户
   - **注册**：创建新账号
3. 在验证码登录页面：
   - 输入手机号
   - 发送验证码
   - 输入验证码登录
   - 首次使用手机号将自动注册账号
   - 可以切换到密码登录
4. 在密码登录页面：
   - 输入手机号
   - 输入密码登录
   - 可以切换到验证码登录

## 登录方式说明

### 验证码登录

- 适合新用户或忘记密码的用户
- 支持自动注册
- 验证码发送有60秒倒计时限制
- 验证码为6位数字

### 密码登录

- 适合已有账号的用户
- 需要用户之前设置过密码
- 支持密码可见性切换
- 密码长度至少6位

## 测试账号

在开发模式下，应用会自动使用以下测试账号登录：

- 邮箱：minchaozhang@163.com
- 密码：1234qwer

## 注意事项

1. 确保 Supabase 配置正确
2. 手机验证码登录支持自动注册
3. 验证码发送有60秒倒计时限制
4. 密码登录需要用户之前设置过密码
5. 所有表单都有验证功能
6. 两个登录页面之间可以自由切换
