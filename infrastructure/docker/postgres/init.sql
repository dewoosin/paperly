-- Paperly 데이터베이스 초기 설정
-- 개발 환경용 초기 스키마

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 기본 스키마 생성
CREATE SCHEMA IF NOT EXISTS paperly;

-- 개발용 샘플 데이터는 마이그레이션으로 관리
