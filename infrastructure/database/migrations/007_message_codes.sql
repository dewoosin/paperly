-- 메시지 코드 테이블 생성
CREATE TABLE IF NOT EXISTS paperly.message_codes (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('SYSTEM', 'ERROR', 'WARNING', 'INFO', 'SUCCESS', 'VALIDATION', 'SECURITY')),
    category VARCHAR(50) NOT NULL,
    message_ko TEXT NOT NULL,
    message_en TEXT NOT NULL,
    description TEXT,
    http_status_code INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX idx_message_codes_code ON paperly.message_codes(code);
CREATE INDEX idx_message_codes_type ON paperly.message_codes(type);
CREATE INDEX idx_message_codes_category ON paperly.message_codes(category);

-- 메시지 코드 데이터 삽입
INSERT INTO paperly.message_codes (code, type, category, message_ko, message_en, http_status_code) VALUES
-- 인증 관련 메시지
('AUTH_001', 'ERROR', 'AUTH', '이메일 또는 비밀번호가 올바르지 않습니다', 'Invalid email or password', 401),
('AUTH_002', 'ERROR', 'AUTH', '인증 토큰이 없습니다', 'No authentication token provided', 401),
('AUTH_003', 'ERROR', 'AUTH', '유효하지 않은 토큰입니다', 'Invalid token', 401),
('AUTH_004', 'ERROR', 'AUTH', '토큰이 만료되었습니다', 'Token expired', 401),
('AUTH_005', 'ERROR', 'AUTH', '권한이 없습니다', 'Access denied', 403),
('AUTH_006', 'SUCCESS', 'AUTH', '로그인 성공', 'Login successful', 200),
('AUTH_007', 'SUCCESS', 'AUTH', '로그아웃 성공', 'Logout successful', 200),
('AUTH_008', 'ERROR', 'AUTH', '이미 존재하는 이메일입니다', 'Email already exists', 409),
('AUTH_009', 'SUCCESS', 'AUTH', '회원가입 성공', 'Registration successful', 201),
('AUTH_010', 'ERROR', 'AUTH', '비밀번호가 일치하지 않습니다', 'Passwords do not match', 400),
('AUTH_011', 'ERROR', 'AUTH', '이메일 인증이 필요합니다', 'Email verification required', 403),
('AUTH_012', 'SUCCESS', 'AUTH', '이메일 인증 완료', 'Email verified successfully', 200),
('AUTH_013', 'ERROR', 'AUTH', '유효하지 않은 인증 코드입니다', 'Invalid verification code', 400),
('AUTH_014', 'INFO', 'AUTH', '인증 이메일이 발송되었습니다', 'Verification email sent', 200),
('AUTH_015', 'ERROR', 'AUTH', 'Refresh token이 유효하지 않습니다', 'Invalid refresh token', 401),
('AUTH_016', 'SUCCESS', 'AUTH', '토큰이 갱신되었습니다', 'Token refreshed successfully', 200),

-- 사용자 관련 메시지
('USER_001', 'ERROR', 'USER', '사용자를 찾을 수 없습니다', 'User not found', 404),
('USER_002', 'SUCCESS', 'USER', '프로필 업데이트 성공', 'Profile updated successfully', 200),
('USER_003', 'ERROR', 'USER', '유효하지 않은 사용자 ID입니다', 'Invalid user ID', 400),
('USER_004', 'ERROR', 'USER', '프로필 이미지 업로드 실패', 'Failed to upload profile image', 500),
('USER_005', 'SUCCESS', 'USER', '비밀번호 변경 성공', 'Password changed successfully', 200),
('USER_006', 'ERROR', 'USER', '현재 비밀번호가 올바르지 않습니다', 'Current password is incorrect', 400),
('USER_007', 'ERROR', 'USER', '이미 사용중인 닉네임입니다', 'Nickname already in use', 409),
('USER_008', 'SUCCESS', 'USER', '사용자 삭제 완료', 'User deleted successfully', 200),

-- 아티클 관련 메시지
('ARTICLE_001', 'ERROR', 'ARTICLE', '글을 찾을 수 없습니다', 'Article not found', 404),
('ARTICLE_002', 'SUCCESS', 'ARTICLE', '글 작성 성공', 'Article created successfully', 201),
('ARTICLE_003', 'SUCCESS', 'ARTICLE', '글 수정 성공', 'Article updated successfully', 200),
('ARTICLE_004', 'SUCCESS', 'ARTICLE', '글 삭제 성공', 'Article deleted successfully', 200),
('ARTICLE_005', 'ERROR', 'ARTICLE', '글 작성 권한이 없습니다', 'No permission to create article', 403),
('ARTICLE_006', 'ERROR', 'ARTICLE', '글 수정 권한이 없습니다', 'No permission to edit article', 403),
('ARTICLE_007', 'ERROR', 'ARTICLE', '글 삭제 권한이 없습니다', 'No permission to delete article', 403),
('ARTICLE_008', 'VALIDATION', 'ARTICLE', '제목을 입력해주세요', 'Title is required', 400),
('ARTICLE_009', 'VALIDATION', 'ARTICLE', '내용을 입력해주세요', 'Content is required', 400),
('ARTICLE_010', 'SUCCESS', 'ARTICLE', '글 발행 성공', 'Article published successfully', 200),
('ARTICLE_011', 'SUCCESS', 'ARTICLE', '글 저장 성공', 'Article saved as draft', 200),
('ARTICLE_012', 'ERROR', 'ARTICLE', '이미 발행된 글입니다', 'Article already published', 400),
('ARTICLE_013', 'SUCCESS', 'ARTICLE', '글 좋아요 완료', 'Article liked successfully', 200),
('ARTICLE_014', 'SUCCESS', 'ARTICLE', '글 좋아요 취소', 'Article unliked successfully', 200),
('ARTICLE_015', 'ERROR', 'ARTICLE', '이미 좋아요한 글입니다', 'Article already liked', 400),

-- 카테고리 관련 메시지
('CATEGORY_001', 'ERROR', 'CATEGORY', '카테고리를 찾을 수 없습니다', 'Category not found', 404),
('CATEGORY_002', 'ERROR', 'CATEGORY', '이미 존재하는 카테고리입니다', 'Category already exists', 409),
('CATEGORY_003', 'SUCCESS', 'CATEGORY', '카테고리 생성 성공', 'Category created successfully', 201),
('CATEGORY_004', 'SUCCESS', 'CATEGORY', '카테고리 수정 성공', 'Category updated successfully', 200),
('CATEGORY_005', 'ERROR', 'CATEGORY', '카테고리에 속한 글이 있어 삭제할 수 없습니다', 'Cannot delete category with articles', 400),

-- 태그 관련 메시지
('TAG_001', 'ERROR', 'TAG', '태그를 찾을 수 없습니다', 'Tag not found', 404),
('TAG_002', 'SUCCESS', 'TAG', '태그 추가 성공', 'Tag added successfully', 200),
('TAG_003', 'SUCCESS', 'TAG', '태그 제거 성공', 'Tag removed successfully', 200),
('TAG_004', 'ERROR', 'TAG', '이미 존재하는 태그입니다', 'Tag already exists', 409),

-- 팔로우 관련 메시지
('FOLLOW_001', 'SUCCESS', 'FOLLOW', '팔로우 성공', 'Followed successfully', 200),
('FOLLOW_002', 'SUCCESS', 'FOLLOW', '언팔로우 성공', 'Unfollowed successfully', 200),
('FOLLOW_003', 'ERROR', 'FOLLOW', '이미 팔로우한 사용자입니다', 'Already following this user', 400),
('FOLLOW_004', 'ERROR', 'FOLLOW', '자기 자신은 팔로우할 수 없습니다', 'Cannot follow yourself', 400),
('FOLLOW_005', 'ERROR', 'FOLLOW', '팔로우하지 않은 사용자입니다', 'Not following this user', 400),

-- 댓글 관련 메시지
('COMMENT_001', 'SUCCESS', 'COMMENT', '댓글 작성 성공', 'Comment created successfully', 201),
('COMMENT_002', 'SUCCESS', 'COMMENT', '댓글 수정 성공', 'Comment updated successfully', 200),
('COMMENT_003', 'SUCCESS', 'COMMENT', '댓글 삭제 성공', 'Comment deleted successfully', 200),
('COMMENT_004', 'ERROR', 'COMMENT', '댓글을 찾을 수 없습니다', 'Comment not found', 404),
('COMMENT_005', 'ERROR', 'COMMENT', '댓글 수정 권한이 없습니다', 'No permission to edit comment', 403),
('COMMENT_006', 'ERROR', 'COMMENT', '댓글 삭제 권한이 없습니다', 'No permission to delete comment', 403),
('COMMENT_007', 'VALIDATION', 'COMMENT', '댓글 내용을 입력해주세요', 'Comment content is required', 400),

-- 시스템 관련 메시지
('SYSTEM_001', 'ERROR', 'SYSTEM', '서버 오류가 발생했습니다', 'Internal server error', 500),
('SYSTEM_002', 'ERROR', 'SYSTEM', '요청을 처리할 수 없습니다', 'Cannot process request', 400),
('SYSTEM_003', 'ERROR', 'SYSTEM', '잘못된 요청입니다', 'Bad request', 400),
('SYSTEM_004', 'ERROR', 'SYSTEM', '리소스를 찾을 수 없습니다', 'Resource not found', 404),
('SYSTEM_005', 'ERROR', 'SYSTEM', '서비스를 일시적으로 사용할 수 없습니다', 'Service temporarily unavailable', 503),
('SYSTEM_006', 'ERROR', 'SYSTEM', '요청 시간이 초과되었습니다', 'Request timeout', 408),
('SYSTEM_007', 'WARNING', 'SYSTEM', '곧 서비스 점검이 예정되어 있습니다', 'Service maintenance scheduled', 200),
('SYSTEM_008', 'INFO', 'SYSTEM', '새로운 버전이 출시되었습니다', 'New version available', 200),

-- 유효성 검사 관련 메시지
('VALIDATION_001', 'VALIDATION', 'VALIDATION', '필수 항목을 입력해주세요', 'Required field missing', 400),
('VALIDATION_002', 'VALIDATION', 'VALIDATION', '올바른 이메일 형식이 아닙니다', 'Invalid email format', 400),
('VALIDATION_003', 'VALIDATION', 'VALIDATION', '비밀번호는 8자 이상이어야 합니다', 'Password must be at least 8 characters', 400),
('VALIDATION_004', 'VALIDATION', 'VALIDATION', '비밀번호는 영문, 숫자, 특수문자를 포함해야 합니다', 'Password must contain letters, numbers, and special characters', 400),
('VALIDATION_005', 'VALIDATION', 'VALIDATION', '파일 크기가 너무 큽니다', 'File size too large', 400),
('VALIDATION_006', 'VALIDATION', 'VALIDATION', '지원하지 않는 파일 형식입니다', 'Unsupported file format', 400),
('VALIDATION_007', 'VALIDATION', 'VALIDATION', '닉네임은 2-20자 사이여야 합니다', 'Nickname must be between 2-20 characters', 400),
('VALIDATION_008', 'VALIDATION', 'VALIDATION', '제목은 100자를 초과할 수 없습니다', 'Title cannot exceed 100 characters', 400),

-- 보안 관련 메시지
('SECURITY_001', 'SECURITY', 'SECURITY', '의심스러운 활동이 감지되었습니다', 'Suspicious activity detected', 403),
('SECURITY_002', 'SECURITY', 'SECURITY', '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요', 'Too many attempts. Please try again later', 429),
('SECURITY_003', 'SECURITY', 'SECURITY', 'IP가 차단되었습니다', 'IP blocked', 403),
('SECURITY_004', 'SECURITY', 'SECURITY', '계정이 잠겼습니다', 'Account locked', 403),
('SECURITY_005', 'WARNING', 'SECURITY', '새로운 기기에서 로그인이 감지되었습니다', 'Login from new device detected', 200),

-- 온보딩 관련 메시지
('ONBOARDING_001', 'SUCCESS', 'ONBOARDING', '관심사 설정 완료', 'Interests saved successfully', 200),
('ONBOARDING_002', 'VALIDATION', 'ONBOARDING', '최소 3개 이상의 관심사를 선택해주세요', 'Please select at least 3 interests', 400),
('ONBOARDING_003', 'SUCCESS', 'ONBOARDING', '온보딩 완료', 'Onboarding completed', 200),
('ONBOARDING_004', 'INFO', 'ONBOARDING', '온보딩을 완료하면 맞춤 추천을 받을 수 있습니다', 'Complete onboarding for personalized recommendations', 200),

-- 추천 관련 메시지
('RECOMMENDATION_001', 'SUCCESS', 'RECOMMENDATION', '추천 목록을 불러왔습니다', 'Recommendations loaded successfully', 200),
('RECOMMENDATION_002', 'INFO', 'RECOMMENDATION', '추천할 콘텐츠가 없습니다', 'No recommendations available', 200),
('RECOMMENDATION_003', 'ERROR', 'RECOMMENDATION', '추천 시스템 오류', 'Recommendation system error', 500),

-- 작가 관련 메시지
('WRITER_001', 'SUCCESS', 'WRITER', '작가 등록 완료', 'Writer registration completed', 201),
('WRITER_002', 'ERROR', 'WRITER', '작가 프로필을 찾을 수 없습니다', 'Writer profile not found', 404),
('WRITER_003', 'SUCCESS', 'WRITER', '작가 프로필 수정 완료', 'Writer profile updated successfully', 200),
('WRITER_004', 'ERROR', 'WRITER', '작가 등록 권한이 없습니다', 'No permission for writer registration', 403),
('WRITER_005', 'VALIDATION', 'WRITER', '작가 소개를 입력해주세요', 'Writer bio is required', 400),

-- 관리자 관련 메시지
('ADMIN_001', 'ERROR', 'ADMIN', '관리자 권한이 필요합니다', 'Admin permission required', 403),
('ADMIN_002', 'SUCCESS', 'ADMIN', '관리자 작업 완료', 'Admin operation completed', 200),
('ADMIN_003', 'WARNING', 'ADMIN', '관리자 활동이 기록됩니다', 'Admin activity is being logged', 200),
('ADMIN_004', 'ERROR', 'ADMIN', '관리자 토큰이 유효하지 않습니다', 'Invalid admin token', 401),

-- 이메일 관련 메시지
('EMAIL_001', 'SUCCESS', 'EMAIL', '이메일 전송 완료', 'Email sent successfully', 200),
('EMAIL_002', 'ERROR', 'EMAIL', '이메일 전송 실패', 'Failed to send email', 500),
('EMAIL_003', 'WARNING', 'EMAIL', '이메일 전송 대기중', 'Email queued for sending', 200),
('EMAIL_004', 'ERROR', 'EMAIL', '이메일 주소를 확인해주세요', 'Please verify email address', 400);

-- 트리거 생성 (updated_at 자동 업데이트)
CREATE OR REPLACE FUNCTION update_message_codes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_message_codes_updated_at_trigger
    BEFORE UPDATE ON paperly.message_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_message_codes_updated_at();