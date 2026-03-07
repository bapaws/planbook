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

-- ============================================
-- 迁移 v3: 为 user_profiles 表添加支付相关字段
-- ============================================
-- 用于记录支付宝支付情况和回调原始数据
-- 如果字段已存在则跳过
DO $$
BEGIN
    -- 添加商户订单号（out_trade_no）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'planbook' 
        AND table_name = 'user_profiles' 
        AND column_name = 'alipay_out_trade_no'
    ) THEN
        ALTER TABLE planbook.user_profiles
        ADD COLUMN alipay_out_trade_no TEXT;
    END IF;

    -- 添加支付宝交易号（trade_no）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'planbook' 
        AND table_name = 'user_profiles' 
        AND column_name = 'alipay_trade_no'
    ) THEN
        ALTER TABLE planbook.user_profiles
        ADD COLUMN alipay_trade_no TEXT;
    END IF;

    -- 添加商品标识（product_id 或 identifier）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'planbook' 
        AND table_name = 'user_profiles' 
        AND column_name = 'product_id'
    ) THEN
        ALTER TABLE planbook.user_profiles
        ADD COLUMN product_id TEXT REFERENCES planbook.store_products(id);
    END IF;

    -- 添加订阅到期时间（如果是订阅类商品）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'planbook' 
        AND table_name = 'user_profiles' 
        AND column_name = 'expires_at'
    ) THEN
        ALTER TABLE planbook.user_profiles
        ADD COLUMN expires_at TIMESTAMPTZ;
    END IF;
END $$;

-- 为商户订单号创建唯一索引（防止重复处理）
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_profiles_alipay_out_trade_no
ON planbook.user_profiles(alipay_out_trade_no)
WHERE alipay_out_trade_no IS NOT NULL;

-- 为支付宝交易号创建索引（便于查询）
CREATE INDEX IF NOT EXISTS idx_user_profiles_alipay_trade_no
ON planbook.user_profiles(alipay_trade_no)
WHERE alipay_trade_no IS NOT NULL;
