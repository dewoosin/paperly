-- =============================================
-- Paperly 스키마 생성 스크립트
-- =============================================

-- 기존 paperly 스키마가 있다면 삭제 (주의: 모든 데이터가 삭제됩니다)
-- DROP SCHEMA IF EXISTS paperly CASCADE;

-- paperly 스키마 생성
CREATE SCHEMA IF NOT EXISTS paperly;

-- 기본 search_path 설정 (선택사항)
-- SET search_path TO paperly, public;

-- 권한 설정 (데이터베이스 사용자에 맞게 수정하세요)
-- GRANT ALL ON SCHEMA paperly TO your_db_user;
-- GRANT CREATE ON SCHEMA paperly TO your_db_user;

COMMENT ON SCHEMA paperly IS 'Paperly AI 맞춤형 학습 앱 스키마';