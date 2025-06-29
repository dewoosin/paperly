-- =============================================
-- public 스키마 정리 스크립트
-- 기존 public 스키마의 테이블을 백업하고 정리
-- =============================================

-- 1. 기존 데이터 백업 (선택사항)
-- 중요한 데이터가 있다면 먼저 백업하세요
-- pg_dump -U your_user -d your_database -n public -f public_backup.sql

-- 2. public 스키마의 모든 테이블 확인
-- 아래 쿼리로 현재 public 스키마에 있는 테이블 목록을 확인하세요
/*
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
*/

-- 3. public 스키마의 특정 테이블 삭제 (주의: 데이터가 모두 삭제됩니다)
-- 필요한 경우 아래 주석을 해제하고 실행하세요
/*
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.articles CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
-- 추가로 삭제할 테이블들...
*/

-- 4. 또는 public 스키마의 모든 테이블을 한번에 삭제 (매우 주의!)
-- 아래 쿼리는 public 스키마의 모든 테이블을 삭제합니다
/*
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
*/

-- 5. search_path 설정 변경
-- paperly 스키마를 기본 스키마로 설정
ALTER DATABASE your_database_name SET search_path TO paperly, public;