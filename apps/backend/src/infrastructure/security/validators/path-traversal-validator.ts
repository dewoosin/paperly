/// Paperly Backend - Path Traversal 및 Command Injection 공격 방지 검증기
/// 
/// 이 파일은 Path Traversal과 Command Injection 공격을 방지하기 위한 입력 검증 로직을 구현합니다.
/// 사용자 입력을 통한 시스템 파일 접근이나 명령어 실행을 차단하여 서버 보안을 강화합니다.
/// 
/// 주요 방어 기능:
/// 1. Path Traversal 방지: ../, ..\, /etc/passwd 등 디렉토리 순회 공격 차단
/// 2. Command Injection 방지: |, &, ;, `, $(, ${} 등 명령어 실행 문자 차단
/// 3. 파일 시스템 보호: 중요 시스템 파일 및 디렉토리 접근 방지
/// 4. 스크립트 실행 방지: 쉘 스크립트 및 인터프리터 실행 차단
/// 5. 환경 변수 보호: 시스템 환경 변수 접근 방지
/// 
/// 보안 접근 방식:
/// - 블랙리스트 + 화이트리스트: 위험 패턴 차단 + 안전 패턴만 허용
/// - 경로 정규화: 상대 경로를 절대 경로로 변환하여 검증
/// - 인코딩 우회 방지: URL 인코딩, 유니코드 등 다양한 인코딩 감지
/// - 플랫폼 대응: Windows, Linux, macOS 등 다양한 OS 환경 고려

import { Logger } from '../../logging/Logger';
import * as path from 'path';

/**
 * Path Traversal 및 Command Injection 검증 결과 인터페이스
 */
export interface PathTraversalValidationResult {
  isValid: boolean;              // 입력값의 안전성 여부
  threats: string[];             // 감지된 위협 유형 목록
  sanitizedValue?: string;       // 새니타이징된 안전한 값
  severity: 'low' | 'medium' | 'high' | 'critical';  // 위협 심각도
  detectedPatterns: string[];    // 감지된 구체적인 공격 패턴
  normalizedPath?: string;       // 정규화된 경로 (경로 입력인 경우)
}

/**
 * Path Traversal 및 Command Injection 위협 유형 열거형
 */
export enum PathThreatType {
  PATH_TRAVERSAL = 'PATH_TRAVERSAL',                  // 디렉토리 순회 공격
  COMMAND_INJECTION = 'COMMAND_INJECTION',            // 명령어 삽입 공격
  SYSTEM_FILE_ACCESS = 'SYSTEM_FILE_ACCESS',          // 시스템 파일 접근
  SCRIPT_EXECUTION = 'SCRIPT_EXECUTION',              // 스크립트 실행
  ENVIRONMENT_ACCESS = 'ENVIRONMENT_ACCESS',          // 환경 변수 접근
  SHELL_METACHAR = 'SHELL_METACHAR',                  // 쉘 메타문자
  ABSOLUTE_PATH = 'ABSOLUTE_PATH',                    // 절대 경로 사용
  SYMBOLIC_LINK = 'SYMBOLIC_LINK',                    // 심볼릭 링크 조작
  NULL_BYTE = 'NULL_BYTE',                            // Null 바이트 삽입
  UNICODE_BYPASS = 'UNICODE_BYPASS'                   // 유니코드 우회
}

/**
 * 입력 컨텍스트 열거형
 * 
 * 입력의 사용 용도에 따라 다른 검증 규칙을 적용하기 위한 분류입니다.
 */
export enum InputContext {
  FILE_PATH = 'FILE_PATH',         // 파일 경로
  FILE_NAME = 'FILE_NAME',         // 파일명
  DIRECTORY = 'DIRECTORY',         // 디렉토리 경로
  URL_PATH = 'URL_PATH',           // URL 경로
  PARAMETER = 'PARAMETER',         // 일반 매개변수
  COMMAND = 'COMMAND',             // 명령어 (매우 제한적)
  SEARCH_QUERY = 'SEARCH_QUERY',   // 검색 쿼리
  USER_INPUT = 'USER_INPUT'        // 일반 사용자 입력
}

/**
 * Path Traversal 및 Command Injection 방지 검증기 클래스
 */
export class PathTraversalValidator {
  private readonly logger = new Logger('PathTraversalValidator');

  // ============================================================================
  // 🗂️ Path Traversal 공격 패턴들
  // ============================================================================
  
  /**
   * 디렉토리 순회 패턴 목록
   * 
   * 다양한 형태의 상위 디렉토리 접근 시도를 감지합니다.
   */
  private readonly PATH_TRAVERSAL_PATTERNS = [
    /\.\.\//g,                    // ../
    /\.\.\\/g,                    // ..\
    /\.\.[\\/]/g,                 // ../ 또는 ..\
    /[\\/]\.\.[\\/]/g,            // /../ 또는 \..\
    /[\\/]\.\./g,                 // /.. 또는 \..
    /\.\.%2[fF]/g,                // ..%2F (URL 인코딩된 /)
    /\.\.%5[cC]/g,                // ..%5C (URL 인코딩된 \)
    /\.\.\u002[fF]/g,             // 유니코드 슬래시
    /\.\.\u005[cC]/g,             // 유니코드 백슬래시
    /%2[eE]%2[eE]%2[fF]/g,        // %2E%2E%2F (URL 인코딩된 ../)
    /%2[eE]%2[eE]%5[cC]/g,        // %2E%2E%5C (URL 인코딩된 ..\)
    /\.\u002E[\\/]/g,             // 유니코드 점과 슬래시
    /0x2e0x2e0x2f/g,              // 16진수 인코딩
    /\.\.\x2[fF]/g,               // 16진수 슬래시
    /\.\.\x5[cC]/g                // 16진수 백슬래시
  ];

  /**
   * 위험한 시스템 파일 및 디렉토리 패턴
   * 
   * 접근하면 안 되는 중요한 시스템 리소스들입니다.
   */
  private readonly DANGEROUS_SYSTEM_PATHS = [
    // Linux/Unix 시스템 파일
    '/etc/passwd', '/etc/shadow', '/etc/hosts', '/etc/hostname',
    '/etc/group', '/etc/sudoers', '/etc/ssh/', '/root/', '/home/',
    '/var/log/', '/var/mail/', '/var/spool/', '/tmp/', '/dev/',
    '/proc/', '/sys/', '/boot/', '/lib/', '/lib64/', '/usr/bin/',
    '/usr/sbin/', '/sbin/', '/bin/',
    
    // Windows 시스템 파일
    'C:\\Windows\\', 'C:\\Program Files\\', 'C:\\Program Files (x86)\\',
    'C:\\Users\\', 'C:\\System Volume Information\\', 'C:\\$Recycle.Bin\\',
    'C:\\ProgramData\\', 'C:\\Windows\\System32\\', 'C:\\Windows\\SysWOW64\\',
    'windows\\system32\\config\\sam', 'windows\\system32\\config\\system',
    'windows\\system32\\config\\security', 'boot.ini', 'ntldr',
    
    // 공통 중요 파일
    '.ssh/', '.aws/', '.config/', 'authorized_keys', 'id_rsa', 'id_dsa',
    'known_hosts', '.bashrc', '.bash_history', '.profile', '.vimrc',
    'web.config', 'httpd.conf', 'nginx.conf', 'my.cnf', 'my.ini',
    '.env', '.environment', 'config.php', 'wp-config.php',
    'database.yml', 'secrets.yml', 'application.yml'
  ];

  /**
   * 절대 경로 패턴
   * 
   * 시스템의 루트부터 시작하는 절대 경로를 감지합니다.
   */
  private readonly ABSOLUTE_PATH_PATTERNS = [
    /^[a-zA-Z]:\\/,               // Windows 드라이브 경로 (C:\)
    /^\//,                        // Unix/Linux 루트 경로 (/)
    /^\\\\[^\\]+\\/,              // UNC 경로 (\\server\)
    /^file:\/\//,                 // File URL scheme
    /^[a-zA-Z]+:\//               // 기타 스키마
  ];

  // ============================================================================
  // 💻 Command Injection 공격 패턴들
  // ============================================================================
  
  /**
   * 쉘 메타문자 목록
   * 
   * 명령어 실행이나 명령어 체이닝에 사용되는 특수 문자들입니다.
   */
  private readonly SHELL_METACHARACTERS = [
    '|',        // 파이프
    '&',        // 백그라운드 실행, AND 연산자
    ';',        // 명령어 구분자
    '(',        // 서브쉘 시작
    ')',        // 서브쉘 종료
    '`',        // 백틱 (명령어 치환)
    '$',        // 변수 참조
    '>',        // 리다이렉션
    '<',        // 입력 리다이렉션
    '*',        // 와일드카드
    '?',        // 와일드카드
    '[',        // 문자 클래스 시작
    ']',        // 문자 클래스 종료
    '{',        // 중괄호 확장 시작
    '}',        // 중괄호 확장 종료
    '~',        // 홈 디렉토리
    '!',        // 히스토리 확장
    '\n',       // 줄바꿈
    '\r'        // 캐리지 리턴
  ];

  /**
   * 명령어 치환 패턴
   * 
   * 명령어를 실행하고 그 결과를 치환하는 패턴들입니다.
   */
  private readonly COMMAND_SUBSTITUTION_PATTERNS = [
    /`[^`]*`/g,                   // 백틱 명령어 치환
    /\$\([^)]*\)/g,               // $() 명령어 치환
    /\$\{[^}]*\}/g,               // ${} 변수 치환
    /\$[a-zA-Z_][a-zA-Z0-9_]*/g, // $VAR 변수 참조
    /\$\d+/g,                     // $1, $2 등 매개변수
    /\$\*/g,                      // $* 모든 매개변수
    /\$@/g,                       // $@ 모든 매개변수
    /\$\?/g,                      // $? 종료 상태
    /\$\$/g,                      // $$ 프로세스 ID
    /\$!/g                        // $! 마지막 백그라운드 프로세스 ID
  ];

  /**
   * 위험한 명령어 패턴
   * 
   * 시스템에 위험을 가할 수 있는 명령어들입니다.
   */
  private readonly DANGEROUS_COMMANDS = [
    // 시스템 정보 수집
    'whoami', 'id', 'groups', 'finger', 'w', 'who', 'last', 'lastlog',
    'ps', 'top', 'htop', 'netstat', 'ss', 'lsof', 'df', 'mount',
    'uname', 'hostnamectl', 'systemctl', 'service', 'crontab',
    
    // 파일 시스템 조작
    'cat', 'head', 'tail', 'less', 'more', 'vi', 'vim', 'nano', 'emacs',
    'cp', 'mv', 'rm', 'rmdir', 'mkdir', 'chmod', 'chown', 'chgrp',
    'find', 'locate', 'grep', 'awk', 'sed', 'sort', 'uniq', 'wc',
    'tar', 'gzip', 'gunzip', 'zip', 'unzip',
    
    // 네트워크 관련
    'ping', 'traceroute', 'nslookup', 'dig', 'host', 'curl', 'wget',
    'nc', 'netcat', 'telnet', 'ssh', 'scp', 'rsync', 'ftp', 'sftp',
    
    // 프로세스 제어
    'kill', 'killall', 'pkill', 'jobs', 'bg', 'fg', 'nohup', 'screen',
    'tmux', 'disown',
    
    // 시스템 제어
    'sudo', 'su', 'passwd', 'useradd', 'userdel', 'usermod', 'groupadd',
    'shutdown', 'reboot', 'halt', 'poweroff', 'init',
    
    // Windows 명령어
    'cmd', 'powershell', 'wmic', 'net', 'reg', 'sc', 'tasklist', 'taskkill',
    'ipconfig', 'systeminfo', 'dir', 'type', 'copy', 'move', 'del',
    'mkdir', 'rmdir', 'attrib', 'cacls', 'icacls'
  ];

  /**
   * 스크립트 인터프리터 및 실행 패턴
   */
  private readonly SCRIPT_INTERPRETERS = [
    'bash', 'sh', 'zsh', 'fish', 'csh', 'tcsh', 'ksh',
    'python', 'python3', 'ruby', 'perl', 'php', 'node', 'nodejs',
    'java', 'javac', 'gcc', 'g++', 'make', 'cmake',
    'powershell', 'cmd.exe', 'wscript', 'cscript'
  ];

  // ============================================================================
  // 🔤 인코딩 및 우회 패턴들
  // ============================================================================
  
  /**
   * URL 인코딩 패턴
   */
  private readonly URL_ENCODING_PATTERNS = [
    /%2[eE]/g,                    // . (점)
    /%2[fF]/g,                    // / (슬래시)
    /%5[cC]/g,                    // \ (백슬래시)
    /%3[aA]/g,                    // : (콜론)
    /%7[cC]/g,                    // | (파이프)
    /%26/g,                       // & (앰퍼샌드)
    /%3[bB]/g,                    // ; (세미콜론)
    /%60/g,                       // ` (백틱)
    /%24/g,                       // $ (달러)
    /%28/g,                       // ( (여는 괄호)
    /%29/g,                       // ) (닫는 괄호)
    /%3[eE]/g,                    // > (보다 큼)
    /%3[cC]/g,                    // < (보다 작음)
    /%2[aA]/g,                    // * (별표)
    /%3[fF]/g,                    // ? (물음표)
    /%00/g                        // NULL 바이트
  ];

  /**
   * 유니코드 우회 패턴
   */
  private readonly UNICODE_BYPASS_PATTERNS = [
    /\u002[eE]/g,                 // 유니코드 점
    /\u002[fF]/g,                 // 유니코드 슬래시
    /\u005[cC]/g,                 // 유니코드 백슬래시
    /\uFF0E/g,                    // 전각 점
    /\uFF0F/g,                    // 전각 슬래시
    /\uFF3C/g,                    // 전각 백슬래시
    /[\u2000-\u200F]/g,           // 다양한 공백 문자
    /[\uFE00-\uFE0F]/g,           // Variation Selector
    /[\u202A-\u202E]/g            // 텍스트 방향 제어 문자
  ];

  // ============================================================================
  // 📊 공개 메서드들
  // ============================================================================

  /**
   * 종합적인 Path Traversal 및 Command Injection 검증 수행
   * 
   * @param input 검증할 입력 문자열
   * @param context 입력 컨텍스트
   * @param fieldName 필드명 (로깅용)
   * @returns 검증 결과 객체
   */
  public validate(
    input: string, 
    context: InputContext = InputContext.USER_INPUT, 
    fieldName?: string
  ): PathTraversalValidationResult {
    if (!input || typeof input !== 'string') {
      return {
        isValid: true,
        threats: [],
        severity: 'low',
        detectedPatterns: []
      };
    }

    const threats: string[] = [];
    const detectedPatterns: string[] = [];
    let severity: 'low' | 'medium' | 'high' | 'critical' = 'low';
    let normalizedPath: string | undefined;

    // 입력 정규화
    const normalizedInput = this.normalizeInput(input);

    // 컨텍스트별 특화 검증
    this.validateByContext(normalizedInput, context, threats, detectedPatterns);

    // 1. Path Traversal 검증
    const pathResult = this.checkPathTraversal(normalizedInput);
    if (pathResult.found) {
      threats.push(PathThreatType.PATH_TRAVERSAL);
      detectedPatterns.push(...pathResult.patterns);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 2. 시스템 파일 접근 검증
    if (this.hasSystemFileAccess(normalizedInput)) {
      threats.push(PathThreatType.SYSTEM_FILE_ACCESS);
      detectedPatterns.push('SYSTEM_FILE_ACCESS');
      severity = this.escalateSeverity(severity, 'critical');
    }

    // 3. 절대 경로 검증
    if (this.hasAbsolutePath(normalizedInput) && context !== InputContext.FILE_PATH) {
      threats.push(PathThreatType.ABSOLUTE_PATH);
      detectedPatterns.push('ABSOLUTE_PATH');
      severity = this.escalateSeverity(severity, 'medium');
    }

    // 4. Command Injection 검증
    const commandResult = this.checkCommandInjection(normalizedInput);
    if (commandResult.found) {
      threats.push(PathThreatType.COMMAND_INJECTION);
      detectedPatterns.push(...commandResult.patterns);
      severity = this.escalateSeverity(severity, 'critical');
    }

    // 5. 쉘 메타문자 검증
    if (this.hasShellMetacharacters(normalizedInput)) {
      threats.push(PathThreatType.SHELL_METACHAR);
      detectedPatterns.push('SHELL_METACHAR');
      severity = this.escalateSeverity(severity, 'high');
    }

    // 6. 스크립트 실행 검증
    if (this.hasScriptExecution(normalizedInput)) {
      threats.push(PathThreatType.SCRIPT_EXECUTION);
      detectedPatterns.push('SCRIPT_EXECUTION');
      severity = this.escalateSeverity(severity, 'critical');
    }

    // 7. 환경 변수 접근 검증
    if (this.hasEnvironmentAccess(normalizedInput)) {
      threats.push(PathThreatType.ENVIRONMENT_ACCESS);
      detectedPatterns.push('ENVIRONMENT_ACCESS');
      severity = this.escalateSeverity(severity, 'high');
    }

    // 8. NULL 바이트 검증
    if (this.hasNullByte(normalizedInput)) {
      threats.push(PathThreatType.NULL_BYTE);
      detectedPatterns.push('NULL_BYTE');
      severity = this.escalateSeverity(severity, 'high');
    }

    // 9. 유니코드 우회 검증
    if (this.hasUnicodeBypass(input)) {
      threats.push(PathThreatType.UNICODE_BYPASS);
      detectedPatterns.push('UNICODE_BYPASS');
      severity = this.escalateSeverity(severity, 'medium');
    }

    // 경로 정규화 (경로 관련 컨텍스트인 경우)
    if (context === InputContext.FILE_PATH || context === InputContext.DIRECTORY) {
      try {
        normalizedPath = path.normalize(normalizedInput);
      } catch (error) {
        // 정규화 실패 시 추가적인 위험 신호
        threats.push(PathThreatType.PATH_TRAVERSAL);
        detectedPatterns.push('NORMALIZATION_FAILED');
        severity = this.escalateSeverity(severity, 'medium');
      }
    }

    const isValid = threats.length === 0;

    // 위협 감지 시 로깅
    if (!isValid) {
      this.logger.warn('Path Traversal/Command Injection 위협 감지', {
        fieldName,
        context,
        threats,
        detectedPatterns,
        severity,
        inputLength: input.length,
        inputPreview: input.substring(0, 100),
        normalizedPath
      });
    }

    return {
      isValid,
      threats,
      severity,
      detectedPatterns,
      normalizedPath
    };
  }

  /**
   * 빠른 검증 (기본적인 패턴만 확인)
   */
  public quickValidate(input: string): boolean {
    if (!input || typeof input !== 'string') {
      return true;
    }

    // 가장 위험한 패턴들만 빠르게 확인
    const quickPatterns = [
      /\.\.\//,                     // Path traversal
      /[|&;`$()]/,                  // Command injection
      /\/etc\/passwd/,              // System file access
      /%00/                         // Null byte
    ];

    return !quickPatterns.some(pattern => pattern.test(input));
  }

  /**
   * 파일 경로 전용 검증
   */
  public validateFilePath(filePath: string, allowAbsolute: boolean = false): boolean {
    if (!filePath || typeof filePath !== 'string') {
      return true;
    }

    const result = this.validate(filePath, InputContext.FILE_PATH);
    
    // 절대 경로 허용 여부에 따른 추가 검증
    if (!allowAbsolute && this.hasAbsolutePath(filePath)) {
      return false;
    }

    return result.isValid;
  }

  /**
   * 파일명 전용 검증
   */
  public validateFileName(fileName: string): boolean {
    if (!fileName || typeof fileName !== 'string') {
      return true;
    }

    // 파일명에는 경로 구분자가 포함되면 안 됨
    if (fileName.includes('/') || fileName.includes('\\')) {
      return false;
    }

    const result = this.validate(fileName, InputContext.FILE_NAME);
    return result.isValid;
  }

  // ============================================================================
  // 🔍 내부 검증 메서드들
  // ============================================================================

  /**
   * 입력 정규화
   */
  private normalizeInput(input: string): string {
    let normalized = input;

    // URL 디코딩
    try {
      normalized = decodeURIComponent(normalized);
    } catch (error) {
      // 디코딩 실패는 그대로 진행
    }

    // HTML 엔티티 디코딩
    normalized = normalized
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&')
      .replace(/&quot;/g, '"')
      .replace(/&#x27;/g, "'")
      .replace(/&#x2F;/g, '/');

    // 유니코드 정규화
    try {
      normalized = normalized.normalize('NFC');
    } catch (error) {
      // 정규화 실패는 그대로 진행
    }

    return normalized;
  }

  /**
   * 컨텍스트별 특화 검증
   */
  private validateByContext(
    input: string,
    context: InputContext,
    threats: string[],
    patterns: string[]
  ): void {
    switch (context) {
      case InputContext.FILE_NAME:
        // 파일명에서는 경로 구분자 금지
        if (/[/\\]/.test(input)) {
          threats.push(PathThreatType.PATH_TRAVERSAL);
          patterns.push('INVALID_FILENAME_CHARS');
        }
        break;
      
      case InputContext.COMMAND:
        // 명령어 컨텍스트에서는 매우 엄격한 검증
        if (!/^[a-zA-Z0-9\s\-_.]+$/.test(input)) {
          threats.push(PathThreatType.COMMAND_INJECTION);
          patterns.push('INVALID_COMMAND_CHARS');
        }
        break;
      
      case InputContext.URL_PATH:
        // URL 경로에서는 특정 문자만 허용
        if (/[<>"|*?]/.test(input)) {
          threats.push(PathThreatType.PATH_TRAVERSAL);
          patterns.push('INVALID_URL_PATH_CHARS');
        }
        break;
    }
  }

  /**
   * Path Traversal 공격 검증
   */
  private checkPathTraversal(input: string): {
    found: boolean;
    patterns: string[];
  } {
    const patterns: string[] = [];

    for (const pattern of this.PATH_TRAVERSAL_PATTERNS) {
      if (pattern.test(input)) {
        patterns.push('PATH_TRAVERSAL_SEQUENCE');
        break;
      }
    }

    return {
      found: patterns.length > 0,
      patterns
    };
  }

  /**
   * 시스템 파일 접근 검증
   */
  private hasSystemFileAccess(input: string): boolean {
    const normalizedInput = input.toLowerCase();
    
    return this.DANGEROUS_SYSTEM_PATHS.some(dangerousPath => {
      const normalizedPath = dangerousPath.toLowerCase();
      return normalizedInput.includes(normalizedPath);
    });
  }

  /**
   * 절대 경로 검증
   */
  private hasAbsolutePath(input: string): boolean {
    return this.ABSOLUTE_PATH_PATTERNS.some(pattern => pattern.test(input));
  }

  /**
   * Command Injection 공격 검증
   */
  private checkCommandInjection(input: string): {
    found: boolean;
    patterns: string[];
  } {
    const patterns: string[] = [];

    // 명령어 치환 패턴 확인
    for (const pattern of this.COMMAND_SUBSTITUTION_PATTERNS) {
      if (pattern.test(input)) {
        patterns.push('COMMAND_SUBSTITUTION');
        break;
      }
    }

    // 위험한 명령어 확인
    const lowerInput = input.toLowerCase();
    for (const command of this.DANGEROUS_COMMANDS) {
      const commandPattern = new RegExp(`\\b${command}\\b`, 'i');
      if (commandPattern.test(input)) {
        patterns.push(`DANGEROUS_COMMAND_${command.toUpperCase()}`);
      }
    }

    return {
      found: patterns.length > 0,
      patterns
    };
  }

  /**
   * 쉘 메타문자 검증
   */
  private hasShellMetacharacters(input: string): boolean {
    return this.SHELL_METACHARACTERS.some(char => input.includes(char));
  }

  /**
   * 스크립트 실행 검증
   */
  private hasScriptExecution(input: string): boolean {
    return this.SCRIPT_INTERPRETERS.some(interpreter => {
      // 정규식 특수문자 이스케이프 처리
      const escapedInterpreter = interpreter.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const pattern = new RegExp(`\\b${escapedInterpreter}\\b`, 'i');
      return pattern.test(input);
    });
  }

  /**
   * 환경 변수 접근 검증
   */
  private hasEnvironmentAccess(input: string): boolean {
    const envPatterns = [
      /\$[A-Z_][A-Z0-9_]*/,        // $ENV_VAR
      /\$\{[A-Z_][A-Z0-9_]*\}/,    // ${ENV_VAR}
      /%[A-Z_][A-Z0-9_]*%/,        // %ENV_VAR% (Windows)
      /\$HOME/i,
      /\$PATH/i,
      /\$USER/i,
      /\$PWD/i
    ];

    return envPatterns.some(pattern => pattern.test(input));
  }

  /**
   * NULL 바이트 검증
   */
  private hasNullByte(input: string): boolean {
    return input.includes('\0') || /%00/.test(input) || /\x00/.test(input);
  }

  /**
   * 유니코드 우회 검증
   */
  private hasUnicodeBypass(input: string): boolean {
    return this.UNICODE_BYPASS_PATTERNS.some(pattern => pattern.test(input)) ||
           this.URL_ENCODING_PATTERNS.some(pattern => pattern.test(input));
  }

  /**
   * 위협 심각도 에스컬레이션
   */
  private escalateSeverity(
    current: 'low' | 'medium' | 'high' | 'critical',
    threat: 'low' | 'medium' | 'high' | 'critical'
  ): 'low' | 'medium' | 'high' | 'critical' {
    const severityLevels = { low: 1, medium: 2, high: 3, critical: 4 };
    
    return severityLevels[threat] > severityLevels[current] ? threat : current;
  }

  /**
   * 검증 통계 조회
   */
  public getValidationStats(): {
    totalValidations: number;
    threatsDetected: number;
    threatTypes: Record<string, number>;
    severityDistribution: Record<string, number>;
  } {
    return {
      totalValidations: 0,
      threatsDetected: 0,
      threatTypes: Object.values(PathThreatType).reduce((acc, type) => {
        acc[type] = 0;
        return acc;
      }, {} as Record<string, number>),
      severityDistribution: {
        low: 0,
        medium: 0,
        high: 0,
        critical: 0
      }
    };
  }
}

/**
 * Path Traversal 검증기 싱글톤 인스턴스
 */
export const pathTraversalValidator = new PathTraversalValidator();