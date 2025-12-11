-- 创建 planbook schema
CREATE SCHEMA IF NOT EXISTS planbook;

-- 设置搜索路径，方便后续操作
SET search_path TO planbook, public;

-- ============================================
-- Schema 权限设置
-- ============================================
-- 授予 authenticated、service_role 使用 planbook schema 的权限
GRANT USAGE ON SCHEMA planbook TO authenticated, service_role;
GRANT ALL ON SCHEMA planbook TO authenticated, service_role;

-- ============================================
-- Tasks 表（任务表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.tasks (
    id TEXT PRIMARY KEY,
    user_id TEXT,
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
    user_id TEXT,
    title TEXT NOT NULL,
    content TEXT,
    images TEXT,
    cover_image TEXT,
    task_id TEXT REFERENCES planbook.tasks(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- Notes 表索引
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON planbook.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_task_id ON planbook.notes(task_id);
CREATE INDEX IF NOT EXISTS idx_notes_deleted_at ON planbook.notes(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- Tags 表（标签表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.tags (
    id TEXT PRIMARY KEY,
    user_id TEXT,
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
    note_id TEXT NOT NULL REFERENCES planbook.notes(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES planbook.tags(id) ON DELETE CASCADE,
    is_parent BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- NoteTags 表索引
CREATE INDEX IF NOT EXISTS idx_note_tags_note_id ON planbook.note_tags(note_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_tag_id ON planbook.note_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_deleted_at ON planbook.note_tags(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- TaskTags 表（任务标签关联表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.task_tags (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL REFERENCES planbook.tasks(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES planbook.tags(id) ON DELETE CASCADE,
    is_parent BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- TaskTags 表索引
CREATE INDEX IF NOT EXISTS idx_task_tags_task_id ON planbook.task_tags(task_id);
CREATE INDEX IF NOT EXISTS idx_task_tags_tag_id ON planbook.task_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_task_tags_deleted_at ON planbook.task_tags(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- TaskActivities 表（任务活动表）
-- ============================================
CREATE TABLE IF NOT EXISTS planbook.task_activities (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    task_id TEXT REFERENCES planbook.tasks(id) ON DELETE SET NULL,
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
    deleted_at TIMESTAMPTZ
);

-- UserProfiles 表索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted_at ON planbook.user_profiles(deleted_at) WHERE deleted_at IS NULL;

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

-- ============================================
-- Tasks 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own tasks"
  ON planbook.tasks FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own tasks"
  ON planbook.tasks FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own tasks"
  ON planbook.tasks FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own tasks"
  ON planbook.tasks FOR DELETE
  USING (auth.uid()::text = user_id);

-- ============================================
-- Notes 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own notes"
  ON planbook.notes FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own notes"
  ON planbook.notes FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own notes"
  ON planbook.notes FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own notes"
  ON planbook.notes FOR DELETE
  USING (auth.uid()::text = user_id);

-- ============================================
-- Tags 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own tags"
  ON planbook.tags FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own tags"
  ON planbook.tags FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own tags"
  ON planbook.tags FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own tags"
  ON planbook.tags FOR DELETE
  USING (auth.uid()::text = user_id);

-- ============================================
-- NoteTags 表 RLS 策略
-- ============================================
-- NoteTags 表需要通过关联的 note 来检查权限
CREATE POLICY "Users can select their own note_tags"
  ON planbook.note_tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM planbook.notes
      WHERE notes.id = note_tags.note_id
      AND notes.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can insert their own note_tags"
  ON planbook.note_tags FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM planbook.notes
      WHERE notes.id = note_tags.note_id
      AND notes.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can update their own note_tags"
  ON planbook.note_tags FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM planbook.notes
      WHERE notes.id = note_tags.note_id
      AND notes.user_id = auth.uid()::text
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM planbook.notes
      WHERE notes.id = note_tags.note_id
      AND notes.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete their own note_tags"
  ON planbook.note_tags FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM planbook.notes
      WHERE notes.id = note_tags.note_id
      AND notes.user_id = auth.uid()::text
    )
  );

-- ============================================
-- TaskTags 表 RLS 策略
-- ============================================
-- TaskTags 表需要通过关联的 task 来检查权限
CREATE POLICY "Users can select their own task_tags"
  ON planbook.task_tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM planbook.tasks
      WHERE tasks.id = task_tags.task_id
      AND tasks.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can insert their own task_tags"
  ON planbook.task_tags FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM planbook.tasks
      WHERE tasks.id = task_tags.task_id
      AND tasks.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can update their own task_tags"
  ON planbook.task_tags FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM planbook.tasks
      WHERE tasks.id = task_tags.task_id
      AND tasks.user_id = auth.uid()::text
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM planbook.tasks
      WHERE tasks.id = task_tags.task_id
      AND tasks.user_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete their own task_tags"
  ON planbook.task_tags FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM planbook.tasks
      WHERE tasks.id = task_tags.task_id
      AND tasks.user_id = auth.uid()::text
    )
  );

-- ============================================
-- TaskActivities 表 RLS 策略
-- ============================================
CREATE POLICY "Users can select their own task_activities"
  ON planbook.task_activities FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own task_activities"
  ON planbook.task_activities FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own task_activities"
  ON planbook.task_activities FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own task_activities"
  ON planbook.task_activities FOR DELETE
  USING (auth.uid()::text = user_id);

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
