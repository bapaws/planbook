-- ============================================
-- 迁移脚本（用于已有数据库升级）
-- ============================================
-- 迁移 v2: 为 Notes 表添加 type 和 focus_at 字段
-- 如果字段已存在则跳过
DO $$
BEGIN
    -- 添加 type 字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'planbook' 
        AND table_name = 'notes' 
        AND column_name = 'type'
    ) THEN
        ALTER TABLE planbook.notes 
        ADD COLUMN type TEXT CHECK (type IN ('journal', 'dailyFocus', 'weeklyFocus'));
        
        CREATE INDEX IF NOT EXISTS idx_notes_type ON planbook.notes(type);
    END IF;

    -- 添加 focus_at 字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'planbook' 
        AND table_name = 'notes' 
        AND column_name = 'focus_at'
    ) THEN
        ALTER TABLE planbook.notes 
        ADD COLUMN focus_at TIMESTAMPTZ;
        
        CREATE INDEX IF NOT EXISTS idx_notes_focus_at ON planbook.notes(focus_at);
    END IF;
END $$;
