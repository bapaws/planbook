-- ============================================
-- 配置 PostgREST 暴露 planbook schema
-- ============================================
-- 注意：pgrst.db_schemas 参数无法通过普通 SQL 命令设置（需要超级用户权限）
-- 请通过 Supabase Dashboard 配置：
-- 1. 进入 Supabase Dashboard
-- 2. 选择项目 -> Settings -> API
-- 3. 在 "Exposed schemas" 中添加 "planbook"
-- 4. 确保保留默认的 public, storage, graphql_public
--
-- 或者，如果您有超级用户权限，可以在 SQL Editor 中执行：
-- ALTER ROLE authenticator SET pgrst.db_schemas = 'public, storage, graphql_public, planbook'; 

-- 创建 planbook schema
CREATE SCHEMA IF NOT EXISTS planbook;

-- 设置搜索路径，方便后续操作
SET search_path TO planbook, public;

-- ============================================
-- Schema 权限设置
-- ============================================
-- 授予 anon、authenticated、service_role 使用 planbook schema 的权限
GRANT USAGE ON SCHEMA planbook TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA planbook TO anon, authenticated, service_role;

-- ============================================
-- Tasks 表（任务表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.tasks (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    
    -- 层级关系
    parent_id TEXT REFERENCES planbook.tasks(id) ON DELETE CASCADE,
    layer INTEGER NOT NULL DEFAULT 0,
    child_count INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0,
    
    -- 任务时间
    start_at TIMESTAMPTZ,
    end_at TIMESTAMPTZ,
    is_all_day BOOLEAN NOT NULL DEFAULT false,
    due_at TIMESTAMPTZ,
    
    -- 重复规则
    recurrence_rule TEXT,
    
    -- 实例分离
    detached_from_task_id TEXT REFERENCES planbook.tasks(id) ON DELETE SET NULL,
    detached_recurrence_at TIMESTAMPTZ,
    detached_reason TEXT,
    
    -- 提醒
    alarms TEXT,
    
    -- 优先级
    priority TEXT,
    
    -- 位置和备注
    location TEXT,
    notes TEXT,
    
    -- 时区
    time_zone TEXT,
    
    -- 时间戳
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- Tasks 表索引
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON planbook.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON planbook.tasks(parent_id);
CREATE INDEX IF NOT EXISTS idx_tasks_detached_from_task_id ON planbook.tasks(detached_from_task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_deleted_at ON planbook.tasks(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- Notes 表（笔记表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.notes (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    images TEXT,
    cover_image TEXT,
    task_id TEXT REFERENCES planbook.tasks(id) ON DELETE SET NULL,
    -- 笔记类型（journal: 日记, dailyFocus: 每日目标, weeklyFocus: 每周目标）
    type TEXT CHECK (type IN ('journal', 'dailyFocus', 'weeklyFocus')),
    -- 目标日期（用于 dailyFocus 和 weeklyFocus 类型，标识目标对应的日期）
    focus_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- Notes 表索引
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON planbook.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_task_id ON planbook.notes(task_id);
CREATE INDEX IF NOT EXISTS idx_notes_type ON planbook.notes(type);
CREATE INDEX IF NOT EXISTS idx_notes_focus_at ON planbook.notes(focus_at);
CREATE INDEX IF NOT EXISTS idx_notes_deleted_at ON planbook.notes(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- Tags 表（标签表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.tags (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    parent_id TEXT REFERENCES planbook.tags(id) ON DELETE CASCADE,
    level INTEGER NOT NULL DEFAULT 0,
    dark_color_scheme TEXT,
    light_color_scheme TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- Tags 表索引
CREATE INDEX IF NOT EXISTS idx_tags_user_id ON planbook.tags(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_parent_id ON planbook.tags(parent_id);
CREATE INDEX IF NOT EXISTS idx_tags_deleted_at ON planbook.tags(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- NoteTags 表（笔记标签关联表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.note_tags (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    note_id TEXT NOT NULL REFERENCES planbook.notes(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES planbook.tags(id) ON DELETE CASCADE,
    linked_tag_id TEXT REFERENCES planbook.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- NoteTags 表索引
CREATE INDEX IF NOT EXISTS idx_note_tags_user_id ON planbook.note_tags(user_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_note_id ON planbook.note_tags(note_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_tag_id ON planbook.note_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_deleted_at ON planbook.note_tags(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- TaskTags 表（任务标签关联表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.task_tags (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id TEXT NOT NULL REFERENCES planbook.tasks(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES planbook.tags(id) ON DELETE CASCADE,
    linked_tag_id TEXT REFERENCES planbook.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- TaskTags 表索引
CREATE INDEX IF NOT EXISTS idx_task_tags_user_id ON planbook.task_tags(user_id);
CREATE INDEX IF NOT EXISTS idx_task_tags_task_id ON planbook.task_tags(task_id);
CREATE INDEX IF NOT EXISTS idx_task_tags_tag_id ON planbook.task_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_task_tags_deleted_at ON planbook.task_tags(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- TaskActivities 表（任务活动表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.task_activities (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id TEXT REFERENCES planbook.tasks(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    activity_type TEXT,
    occurrence_at TIMESTAMPTZ,
    start_at TIMESTAMPTZ,
    end_at TIMESTAMPTZ,
    duration INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- TaskActivities 表索引
CREATE INDEX IF NOT EXISTS idx_task_activities_user_id ON planbook.task_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_task_activities_task_id ON planbook.task_activities(task_id);
CREATE INDEX IF NOT EXISTS idx_task_activities_occurrence_at ON planbook.task_activities(occurrence_at);
CREATE INDEX IF NOT EXISTS idx_task_activities_deleted_at ON planbook.task_activities(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- UserProfiles 表（用户资料表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT,
    avatar TEXT,
    gender TEXT CHECK (gender IN ('male', 'female', 'unknown')),
    birthday TIMESTAMPTZ,
    last_launch_app_at TIMESTAMPTZ,
    launch_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    
    -- 商户订单号（out_trade_no）
    alipay_out_trade_no TEXT,
    -- 支付宝交易号（trade_no）
    alipay_trade_no TEXT,
    -- 支付金额
    payment_amount DECIMAL(10, 2),
    -- 商品标识（product_id 或 identifier）
    product_id TEXT REFERENCES planbook.store_products(id),
    -- 订阅到期时间（如果是订阅类商品）
    expires_at TIMESTAMPTZ


    -- 按年份的封面设置：JSON 对象，key 为年份字符串（如 "2026"），value 为封面地址（远端 URL 或 App 内置资源路径等）
    cover_by_year JSONB NOT NULL DEFAULT '{}'::jsonb,
);

-- UserProfiles 表索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted_at ON planbook.user_profiles(deleted_at) WHERE deleted_at IS NULL;
-- 为商户订单号创建唯一索引（防止重复处理）
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_profiles_alipay_out_trade_no
ON planbook.user_profiles(alipay_out_trade_no)
WHERE alipay_out_trade_no IS NOT NULL;
-- 为支付宝交易号创建索引（便于查询）
CREATE INDEX IF NOT EXISTS idx_user_profiles_alipay_trade_no
ON planbook.user_profiles(alipay_trade_no)
WHERE alipay_trade_no IS NOT NULL;

-- ============================================
-- StoreProducts 表（应用内商品信息表）
-- ============================================
-- 用于存储应用内购买商品信息，完全对应 RevenueCat SDK 中的 StoreProduct
CREATE TABLE IF NOT EXISTS planbook.store_products (
    id TEXT PRIMARY KEY,
    -- 平台（ios, android, all）
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'all')),
    -- 产品标题
    title TEXT NOT NULL,
    -- 产品描述
    description TEXT,
    -- 价格（double，本地货币）
    price DECIMAL(10, 2) NOT NULL,
    -- 格式化价格字符串（包含货币符号）
    price_string TEXT NOT NULL,
    -- 货币代码（如：USD, CNY）
    currency_code TEXT NOT NULL,
    -- 订阅周期（ISO 8601 格式，如：P1W, P1M, P3M, P6M, P1Y）
    -- P1W = 1周, P1M = 1月, P3M = 3月, P6M = 6月, P1Y = 1年
    subscription_period TEXT,
    -- 是否启用
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    -- 排序顺序
    "order" INTEGER NOT NULL DEFAULT 0,
    -- 时间戳
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- StoreProducts 表索引
CREATE INDEX IF NOT EXISTS idx_store_products_platform ON planbook.store_products(platform);
CREATE INDEX IF NOT EXISTS idx_store_products_is_enabled ON planbook.store_products(is_enabled) WHERE is_enabled = true;
CREATE INDEX IF NOT EXISTS idx_store_products_deleted_at ON planbook.store_products(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_store_products_order ON planbook.store_products("order");

-- ============================================
-- Orders 表（订单表）
-- ============================================
-- 用于保存所有支付宝订单记录
-- 支持订单状态流转：pending -> paid -> failed/refunded
CREATE TABLE IF NOT EXISTS planbook.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- 用户 ID
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- 商品 ID
  product_id TEXT NOT NULL REFERENCES planbook.store_products(id),
  -- 商户订单号（唯一）
  out_trade_no TEXT NOT NULL UNIQUE,
  -- 支付宝交易号（支付成功后才有）
  trade_no TEXT,
  -- 订单状态：pending（待支付）、paid（已支付）、failed（失败）、refunded（已退款）
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed', 'refunded')),
  -- 支付金额
  amount DECIMAL(10, 2) NOT NULL,
  -- 货币代码
  currency_code TEXT NOT NULL DEFAULT 'CNY',
  -- 订阅到期时间（支付成功后计算）
  expires_at TIMESTAMPTZ,
  -- 权益是否已发放（支付成功并同步用户订阅后为 true）
  benefit_granted BOOLEAN NOT NULL DEFAULT FALSE,
  -- 该订单的订阅周期（从商品表复制，便于退款时计算扣回天数）
  -- 格式：P1W / P1M / P3M / P6M / P1Y
  subscription_period TEXT,
  -- 支付回调原始数据（JSON）
  callback_data JSONB,
  -- 订单创建时间
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- 订单更新时间
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- 支付完成时间
  paid_at TIMESTAMPTZ,
  -- 软删除
  deleted_at TIMESTAMPTZ
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON planbook.orders(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_out_trade_no ON planbook.orders(out_trade_no) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_trade_no ON planbook.orders(trade_no) WHERE deleted_at IS NULL AND trade_no IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_status ON planbook.orders(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON planbook.orders(created_at DESC) WHERE deleted_at IS NULL;

-- 添加注释
COMMENT ON TABLE planbook.orders IS '支付宝订单表，记录所有订单创建和支付状态';
COMMENT ON COLUMN planbook.orders.status IS '订单状态：pending（待支付）、paid（已支付）、failed（失败）、refunded（已退款）';
COMMENT ON COLUMN planbook.orders.out_trade_no IS '商户订单号，格式：pb_{user_id}_{timestamp}';
COMMENT ON COLUMN planbook.orders.trade_no IS '支付宝交易号，支付成功后由支付宝返回';
COMMENT ON COLUMN planbook.orders.benefit_granted IS '权益是否已发放，支付成功并同步用户订阅后为 true';
COMMENT ON COLUMN planbook.orders.subscription_period IS '该订单的订阅周期（P1W/P1M/P3M/P6M/P1Y），从商品表复制，便于退款时扣回';

-- ============================================
-- 表权限设置
-- ============================================
-- 授予 authenticated、service_role 对所有表的操作权限
GRANT ALL ON planbook.tasks TO authenticated, service_role;
GRANT ALL ON planbook.notes TO authenticated, service_role;
GRANT ALL ON planbook.tags TO authenticated, service_role;
GRANT ALL ON planbook.note_tags TO authenticated, service_role;
GRANT ALL ON planbook.task_tags TO authenticated, service_role;
GRANT ALL ON planbook.task_activities TO authenticated, service_role;
GRANT ALL ON planbook.user_profiles TO authenticated, service_role;
GRANT ALL ON planbook.store_products TO authenticated, service_role;
GRANT ALL ON planbook.orders TO service_role;

-- ============================================
-- 启用 Row Level Security (RLS)
-- ============================================
-- 为所有表启用 RLS
ALTER TABLE planbook.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.note_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.task_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.task_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.store_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE planbook.orders ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Tasks 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own tasks"
  ON planbook.tasks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tasks"
  ON planbook.tasks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tasks"
  ON planbook.tasks FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tasks"
  ON planbook.tasks FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- Notes 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own notes"
  ON planbook.notes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notes"
  ON planbook.notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notes"
  ON planbook.notes FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notes"
  ON planbook.notes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- Tags 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own tags"
  ON planbook.tags FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tags"
  ON planbook.tags FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tags"
  ON planbook.tags FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tags"
  ON planbook.tags FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- NoteTags 表 RLS 策略
-- ============================================
-- NoteTags 表需要通过关联的 note 来检查权限
CREATE POLICY "Users can select their own note_tags"
  ON planbook.note_tags FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own note_tags"
  ON planbook.note_tags FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own note_tags"
  ON planbook.note_tags FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own note_tags"
  ON planbook.note_tags FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- TaskTags 表 RLS 策略
-- ============================================
-- TaskTags 表需要通过关联的 task 来检查权限
CREATE POLICY "Users can select their own task_tags"
  ON planbook.task_tags FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own task_tags"
  ON planbook.task_tags FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own task_tags"
  ON planbook.task_tags FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own task_tags"
  ON planbook.task_tags FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- TaskActivities 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own task_activities"
  ON planbook.task_activities FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own task_activities"
  ON planbook.task_activities FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own task_activities"
  ON planbook.task_activities FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own task_activities"
  ON planbook.task_activities FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- UserProfiles 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own user_profiles"
  ON planbook.user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own user_profiles"
  ON planbook.user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own user_profiles"
  ON planbook.user_profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own user_profiles"
  ON planbook.user_profiles FOR DELETE
  USING (auth.uid() = id);

-- ============================================
-- StoreProducts 表 RLS 策略
-- ============================================
-- 商品信息表对所有认证用户只读（公开信息）
CREATE POLICY "Allow authenticated users to select store products"
  ON planbook.store_products FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL AND is_enabled = true);

-- 只有 service_role 可以管理商品信息（插入、更新、删除）
-- 注意：这些操作应该通过后端服务或管理员界面完成
CREATE POLICY "Allow service role to manage store products"
  ON planbook.store_products FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================
-- Orders 表 RLS 策略
-- ============================================
CREATE POLICY "Allow service role to manage orders"
  ON planbook.orders FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================
-- Storage Buckets（存储桶）
-- ============================================
-- 创建 planbook-note-images bucket（笔记图片存储桶）
-- 注意：如果 bucket 已存在，此操作不会报错（ON CONFLICT DO NOTHING）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'planbook-note-images'::text,
  'planbook-note-images',
  false, -- 私有 bucket
  52428800, -- 50MB 文件大小限制
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']::text[] -- 允许的 MIME 类型
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Storage Objects RLS 策略（planbook-note-images）
-- ============================================
-- 允许认证用户上传文件到 planbook-note-images bucket
-- 文件路径格式：{userId}/{filename} 或 planbook/{filename}
CREATE POLICY "Allow authenticated users to upload note images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id::text = 'planbook-note-images' AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 允许用户访问自己上传的笔记图片（通过文件夹路径检查）
CREATE POLICY "Allow users to access their own note images"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id::text = 'planbook-note-images' AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 允许用户更新自己上传的笔记图片
CREATE POLICY "Allow users to update their own note images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id::text = 'planbook-note-images' AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 允许用户删除自己上传的笔记图片
CREATE POLICY "Allow users to delete their own note images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id::text = 'planbook-note-images' AND (storage.foldername(name))[1] = auth.uid()::text
  );
