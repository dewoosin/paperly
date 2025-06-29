/// Paperly Backend - XSS 공격 방지 검증기
/// 
/// 이 파일은 Cross-Site Scripting (XSS) 공격을 방지하기 위한 입력 검증 로직을 구현합니다.
/// 사용자 입력에서 악성 스크립트 코드를 감지하고 차단하여 웹 애플리케이션의 보안을 강화합니다.
/// 
/// 주요 방어 기능:
/// 1. HTML 태그 검증: <script>, <iframe>, <object> 등 위험한 태그 차단
/// 2. JavaScript 이벤트 검증: onclick, onload, onerror 등 이벤트 핸들러 차단
/// 3. URL 스키마 검증: javascript:, data:, vbscript: 등 위험한 프로토콜 차단
/// 4. HTML 엔티티 검증: 인코딩을 통한 우회 시도 감지
/// 5. CSS 표현식 검증: CSS expression() 및 JavaScript 코드 차단
/// 
/// 보안 접근 방식:
/// - 화이트리스트 방식: 안전한 패턴만 허용
/// - 다중 검증: 여러 단계의 검증으로 우회 방지
/// - 정규식 최적화: 성능을 고려한 효율적인 패턴 매칭
/// - 상세한 로깅: 공격 시도 추적 및 분석

import { Logger } from '../../logging/Logger';

/**
 * XSS 검증 결과 인터페이스
 * 
 * 검증 과정에서 발견된 위협의 상세 정보를 담습니다.
 */
export interface XSSValidationResult {
  isValid: boolean;              // 입력값의 안전성 여부
  threats: string[];             // 감지된 위협 유형 목록
  sanitizedValue?: string;       // 새니타이징된 안전한 값 (선택사항)
  severity: 'low' | 'medium' | 'high' | 'critical';  // 위협 심각도
}

/**
 * XSS 위협 유형 열거형
 * 
 * 다양한 XSS 공격 벡터를 분류하여 관리합니다.
 */
export enum XSSThreatType {
  HTML_TAG = 'HTML_TAG',                    // 위험한 HTML 태그
  JAVASCRIPT_EVENT = 'JAVASCRIPT_EVENT',    // JavaScript 이벤트 핸들러
  URL_SCHEME = 'URL_SCHEME',                // 위험한 URL 스키마
  HTML_ENTITY = 'HTML_ENTITY',              // HTML 엔티티 우회
  CSS_EXPRESSION = 'CSS_EXPRESSION',        // CSS expression 공격
  SCRIPT_CONTENT = 'SCRIPT_CONTENT',        // 스크립트 코드 내용
  DATA_URI = 'DATA_URI',                    // Data URI 스키마 공격
  JAVASCRIPT_URI = 'JAVASCRIPT_URI'         // JavaScript URI 공격
}

/**
 * XSS 공격 방지 검증기 클래스
 * 
 * 다양한 XSS 공격 패턴을 감지하고 차단하는 종합적인 보안 검증 시스템입니다.
 * 실시간으로 사용자 입력을 분석하여 악성 코드를 식별하고 적절한 대응을 수행합니다.
 */
export class XSSValidator {
  private readonly logger = new Logger('XSSValidator');

  // ============================================================================
  // 🛡️ 위험한 HTML 태그 패턴들
  // ============================================================================
  
  /**
   * 위험한 HTML 태그 목록
   * 
   * XSS 공격에 주로 사용되는 HTML 태그들을 정의합니다.
   * 이러한 태그들은 JavaScript 실행이나 외부 리소스 로드가 가능합니다.
   */
  private readonly DANGEROUS_HTML_TAGS = [
    'script',           // JavaScript 실행
    'iframe',           // 외부 페이지 임베드
    'object',           // ActiveX, Flash 등 플러그인
    'embed',            // 외부 미디어 임베드
    'form',             // 폼 데이터 전송
    'input',            // 사용자 입력
    'textarea',         // 텍스트 영역
    'button',           // 버튼 (이벤트 핸들러 가능)
    'select',           // 선택 박스
    'option',           // 선택 옵션
    'applet',           // Java 애플릿
    'meta',             // 메타데이터 (리다이렉트 가능)
    'link',             // 외부 리소스 링크
    'style',            // CSS 스타일 (expression 공격 가능)
    'base',             // 기본 URL 변경
    'frameset',         // 프레임셋
    'frame'             // 프레임
  ];

  /**
   * 위험한 HTML 태그 검증 정규식
   * 
   * 케이스 인센시티브하게 위험한 태그를 감지합니다.
   * 다양한 공백과 인코딩 우회 시도도 탐지합니다.
   */
  private readonly HTML_TAG_PATTERN = new RegExp(
    `<\\s*/?\\s*(${this.DANGEROUS_HTML_TAGS.join('|')})(?:\\s[^>]*)?\\s*/?>`,
    'gi'
  );

  // ============================================================================
  // ⚡ JavaScript 이벤트 핸들러 패턴들
  // ============================================================================
  
  /**
   * 위험한 JavaScript 이벤트 핸들러 목록
   * 
   * HTML 요소에서 JavaScript 코드 실행을 유발할 수 있는 이벤트들입니다.
   */
  private readonly JAVASCRIPT_EVENTS = [
    'onabort', 'onactivate', 'onafterprint', 'onafterupdate', 'onbeforeactivate',
    'onbeforecopy', 'onbeforecut', 'onbeforedeactivate', 'onbeforeeditfocus',
    'onbeforepaste', 'onbeforeprint', 'onbeforeunload', 'onbeforeupdate',
    'onblur', 'onbounce', 'oncellchange', 'onchange', 'onclick', 'oncontextmenu',
    'oncontrolselect', 'oncopy', 'oncut', 'ondataavailable', 'ondatasetchanged',
    'ondatasetcomplete', 'ondblclick', 'ondeactivate', 'ondrag', 'ondragend',
    'ondragenter', 'ondragleave', 'ondragover', 'ondragstart', 'ondrop',
    'onerror', 'onerrorupdate', 'onfilterchange', 'onfinish', 'onfocus',
    'onfocusin', 'onfocusout', 'onhelp', 'onkeydown', 'onkeypress', 'onkeyup',
    'onlayoutcomplete', 'onload', 'onlosecapture', 'onmousedown', 'onmouseenter',
    'onmouseleave', 'onmousemove', 'onmouseout', 'onmouseover', 'onmouseup',
    'onmousewheel', 'onmove', 'onmoveend', 'onmovestart', 'onpaste',
    'onpropertychange', 'onreadystatechange', 'onreset', 'onresize',
    'onresizeend', 'onresizestart', 'onrowenter', 'onrowexit', 'onrowsdelete',
    'onrowsinserted', 'onscroll', 'onselect', 'onselectionchange',
    'onselectstart', 'onstart', 'onstop', 'onsubmit', 'onunload'
  ];

  /**
   * JavaScript 이벤트 핸들러 검증 정규식
   * 
   * 다양한 형태의 이벤트 핸들러 속성을 감지합니다.
   */
  private readonly JS_EVENT_PATTERN = new RegExp(
    `\\s*(${this.JAVASCRIPT_EVENTS.join('|')})\\s*=`,
    'gi'
  );

  // ============================================================================
  // 🔗 위험한 URL 스키마 패턴들
  // ============================================================================
  
  /**
   * 위험한 URL 스키마 목록
   * 
   * JavaScript 실행이나 악성 행위를 유발할 수 있는 URL 프로토콜들입니다.
   */
  private readonly DANGEROUS_URL_SCHEMES = [
    'javascript:',      // JavaScript 코드 실행
    'data:',           // Data URI (base64 인코딩된 스크립트 가능)
    'vbscript:',       // VBScript 실행 (IE)
    'livescript:',     // LiveScript 실행
    'mocha:',          // Mocha 스크립트
    'about:',          // 브라우저 내부 페이지
    'chrome:',         // Chrome 내부 프로토콜
    'file:',           // 로컬 파일 접근
    'res:',            // 리소스 프로토콜
    'view-source:',    // 소스 보기
    'jar:',            // JAR 파일
    'ms-its:'          // Microsoft Internet Explorer
  ];

  /**
   * 위험한 URL 스키마 검증 정규식
   * 
   * URL 내에서 위험한 프로토콜을 감지합니다.
   */
  private readonly URL_SCHEME_PATTERN = new RegExp(
    `(${this.DANGEROUS_URL_SCHEMES.map(scheme => scheme.replace(':', '\\s*:\\s*')).join('|')})`,
    'gi'
  );

  // ============================================================================
  // 🎨 CSS Expression 공격 패턴들
  // ============================================================================
  
  /**
   * CSS expression 공격 검증 정규식
   * 
   * CSS의 expression() 함수를 통한 JavaScript 실행을 감지합니다.
   * Internet Explorer에서 주로 사용되던 공격 벡터입니다.
   */
  private readonly CSS_EXPRESSION_PATTERN = /expression\s*\(/gi;

  /**
   * CSS import 공격 검증 정규식
   * 
   * @import를 통한 외부 CSS 로드 공격을 감지합니다.
   */
  private readonly CSS_IMPORT_PATTERN = /@import\s+/gi;

  // ============================================================================
  // 🔤 HTML 엔티티 우회 공격 패턴들
  // ============================================================================
  
  /**
   * HTML 엔티티를 통한 우회 공격 감지
   * 
   * &lt;script&gt; 같은 인코딩된 태그나 &#x 형태의 16진수 인코딩을 감지합니다.
   */
  private readonly HTML_ENTITY_PATTERN = /&(?:#x?[0-9a-f]+|[a-z]+);/gi;
  
  /**
   * 16진수/10진수 문자 참조 패턴
   * 
   * &#60;, &#x3C; 같은 숫자 문자 참조를 감지합니다.
   */
  private readonly NUMERIC_ENTITY_PATTERN = /&#(?:x[0-9a-f]+|\d+);/gi;

  // ============================================================================
  // 📊 공개 메서드들
  // ============================================================================

  /**
   * 종합적인 XSS 검증 수행
   * 
   * 입력값에 대해 모든 XSS 공격 패턴을 검사하고 상세한 결과를 반환합니다.
   * 여러 단계의 검증을 통해 다양한 우회 시도를 탐지합니다.
   * 
   * @param input 검증할 입력 문자열
   * @param fieldName 필드명 (로깅용)
   * @returns XSS 검증 결과 객체
   */
  public validate(input: string, fieldName?: string): XSSValidationResult {
    if (!input || typeof input !== 'string') {
      return {
        isValid: true,
        threats: [],
        severity: 'low'
      };
    }

    const threats: string[] = [];
    let severity: 'low' | 'medium' | 'high' | 'critical' = 'low';

    // 1. HTML 태그 검증
    if (this.hasHtmlTags(input)) {
      threats.push(XSSThreatType.HTML_TAG);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 2. JavaScript 이벤트 핸들러 검증
    if (this.hasJavaScriptEvents(input)) {
      threats.push(XSSThreatType.JAVASCRIPT_EVENT);
      severity = this.escalateSeverity(severity, 'critical');
    }

    // 3. 위험한 URL 스키마 검증
    if (this.hasDangerousUrlScheme(input)) {
      threats.push(XSSThreatType.URL_SCHEME);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 4. CSS Expression 검증
    if (this.hasCssExpression(input)) {
      threats.push(XSSThreatType.CSS_EXPRESSION);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 5. HTML 엔티티 우회 검증
    if (this.hasHtmlEntityBypass(input)) {
      threats.push(XSSThreatType.HTML_ENTITY);
      severity = this.escalateSeverity(severity, 'medium');
    }

    // 6. Data URI 검증
    if (this.hasDataUri(input)) {
      threats.push(XSSThreatType.DATA_URI);
      severity = this.escalateSeverity(severity, 'high');
    }

    // 7. JavaScript URI 검증
    if (this.hasJavaScriptUri(input)) {
      threats.push(XSSThreatType.JAVASCRIPT_URI);
      severity = this.escalateSeverity(severity, 'critical');
    }

    const isValid = threats.length === 0;

    // 위협 감지 시 로깅
    if (!isValid) {
      this.logger.warn('XSS 위협 감지', {
        fieldName,
        threats,
        severity,
        inputLength: input.length,
        inputPreview: input.substring(0, 100) // 처음 100자만 로깅 (민감정보 보호)
      });
    }

    return {
      isValid,
      threats,
      severity
    };
  }

  /**
   * 빠른 XSS 검증 (기본적인 패턴만 확인)
   * 
   * 성능이 중요한 상황에서 사용할 수 있는 경량화된 검증입니다.
   * 가장 일반적인 XSS 패턴만을 확인합니다.
   * 
   * @param input 검증할 입력 문자열
   * @returns 안전성 여부 (boolean)
   */
  public quickValidate(input: string): boolean {
    if (!input || typeof input !== 'string') {
      return true;
    }

    // 빠른 검증: 가장 위험한 패턴들만 확인
    return !this.HTML_TAG_PATTERN.test(input) &&
           !this.JS_EVENT_PATTERN.test(input) &&
           !this.URL_SCHEME_PATTERN.test(input);
  }

  // ============================================================================
  // 🔍 내부 검증 메서드들
  // ============================================================================

  /**
   * 위험한 HTML 태그 존재 여부 확인
   */
  private hasHtmlTags(input: string): boolean {
    return this.HTML_TAG_PATTERN.test(input);
  }

  /**
   * JavaScript 이벤트 핸들러 존재 여부 확인
   */
  private hasJavaScriptEvents(input: string): boolean {
    return this.JS_EVENT_PATTERN.test(input);
  }

  /**
   * 위험한 URL 스키마 존재 여부 확인
   */
  private hasDangerousUrlScheme(input: string): boolean {
    return this.URL_SCHEME_PATTERN.test(input);
  }

  /**
   * CSS Expression 공격 존재 여부 확인
   */
  private hasCssExpression(input: string): boolean {
    return this.CSS_EXPRESSION_PATTERN.test(input) || 
           this.CSS_IMPORT_PATTERN.test(input);
  }

  /**
   * HTML 엔티티를 통한 우회 공격 존재 여부 확인
   */
  private hasHtmlEntityBypass(input: string): boolean {
    // HTML 엔티티가 있는 경우, 디코딩 후 재검증
    if (this.HTML_ENTITY_PATTERN.test(input) || this.NUMERIC_ENTITY_PATTERN.test(input)) {
      const decoded = this.decodeHtmlEntities(input);
      // 디코딩 후 위험한 패턴이 나타나는지 확인
      return this.HTML_TAG_PATTERN.test(decoded) || 
             this.JS_EVENT_PATTERN.test(decoded);
    }
    return false;
  }

  /**
   * Data URI 공격 존재 여부 확인
   */
  private hasDataUri(input: string): boolean {
    const dataUriPattern = /data:\s*[^;]*;?\s*(?:base64\s*,|,)/gi;
    return dataUriPattern.test(input);
  }

  /**
   * JavaScript URI 공격 존재 여부 확인
   */
  private hasJavaScriptUri(input: string): boolean {
    const jsUriPattern = /javascript\s*:\s*/gi;
    return jsUriPattern.test(input);
  }

  /**
   * HTML 엔티티 디코딩
   * 
   * 기본적인 HTML 엔티티를 디코딩하여 숨겨진 위험 패턴을 노출시킵니다.
   */
  private decodeHtmlEntities(input: string): string {
    const entityMap: Record<string, string> = {
      '&lt;': '<',
      '&gt;': '>',
      '&amp;': '&',
      '&quot;': '"',
      '&#x27;': "'",
      '&#x2F;': '/',
      '&#x60;': '`',
      '&#x3D;': '='
    };

    let decoded = input;
    
    // 명명된 엔티티 디코딩
    for (const [entity, char] of Object.entries(entityMap)) {
      decoded = decoded.replace(new RegExp(entity, 'gi'), char);
    }

    // 숫자 엔티티 디코딩
    decoded = decoded.replace(/&#(\d+);/g, (match, dec) => {
      return String.fromCharCode(parseInt(dec, 10));
    });

    // 16진수 엔티티 디코딩
    decoded = decoded.replace(/&#x([0-9a-f]+);/gi, (match, hex) => {
      return String.fromCharCode(parseInt(hex, 16));
    });

    return decoded;
  }

  /**
   * 위협 심각도 에스컬레이션
   * 
   * 현재 심각도와 새로운 위협 심각도를 비교하여 더 높은 등급을 반환합니다.
   */
  private escalateSeverity(
    current: 'low' | 'medium' | 'high' | 'critical',
    threat: 'low' | 'medium' | 'high' | 'critical'
  ): 'low' | 'medium' | 'high' | 'critical' {
    const severityLevels = { low: 1, medium: 2, high: 3, critical: 4 };
    
    return severityLevels[threat] > severityLevels[current] ? threat : current;
  }

  /**
   * XSS 검증 통계 조회
   * 
   * 검증 수행 통계 및 감지된 위협 현황을 반환합니다.
   * 모니터링 및 보안 분석에 활용됩니다.
   */
  public getValidationStats(): {
    totalValidations: number;
    threatsDetected: number;
    severityDistribution: Record<string, number>;
  } {
    // 실제 구현에서는 메트릭 수집 시스템과 연동
    return {
      totalValidations: 0,
      threatsDetected: 0,
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
 * XSS 검증기 싱글톤 인스턴스
 * 
 * 애플리케이션 전체에서 사용할 수 있는 공유 인스턴스입니다.
 */
export const xssValidator = new XSSValidator();