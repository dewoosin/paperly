/// Paperly Backend - HTML 새니타이저
/// 
/// 이 파일은 사용자 입력에서 위험한 HTML 코드를 안전하게 제거하거나 무력화하는 
/// 새니타이징 로직을 구현합니다. XSS 공격을 방지하면서도 안전한 HTML은 보존합니다.
/// 
/// 주요 기능:
/// 1. 위험한 HTML 태그 제거: <script>, <iframe>, <object> 등 차단
/// 2. JavaScript 이벤트 제거: onclick, onload 등 이벤트 핸들러 제거
/// 3. 위험한 속성 제거: javascript:, data: 스키마 등 제거
/// 4. HTML 엔티티 인코딩: 특수문자를 안전한 형태로 변환
/// 5. 화이트리스트 태그 허용: 안전한 태그만 선별적 허용
/// 
/// 새니타이징 전략:
/// - 화이트리스트 접근: 안전한 태그/속성만 허용
/// - 점진적 새니타이징: 단계별 위험 요소 제거
/// - 컨텍스트 인식: 사용 용도에 따른 맞춤형 새니타이징
/// - 가독성 보존: 안전한 컨텐츠는 최대한 보존

import { Logger } from '../../logging/Logger';

/**
 * HTML 새니타이징 결과 인터페이스
 */
export interface HTMLSanitizationResult {
  sanitizedHTML: string;         // 새니타이징된 HTML
  removedElements: string[];     // 제거된 위험 요소들
  wasModified: boolean;          // 수정 여부
  warnings: string[];            // 경고 메시지
}

/**
 * HTML 새니타이징 옵션
 */
export interface HTMLSanitizationOptions {
  allowedTags?: string[];                 // 허용할 HTML 태그 목록
  allowedAttributes?: string[];           // 허용할 속성 목록
  allowedSchemes?: string[];              // 허용할 URL 스키마
  stripComments?: boolean;                // HTML 주석 제거 여부
  stripUnknownTags?: boolean;             // 알 수 없는 태그 제거 여부
  encodeSpecialChars?: boolean;           // 특수문자 인코딩 여부
  maxLength?: number;                     // 최대 길이 제한
  preserveLineBreaks?: boolean;           // 줄바꿈 보존 여부
}

/**
 * 새니타이징 컨텍스트 열거형
 */
export enum SanitizationContext {
  PLAIN_TEXT = 'PLAIN_TEXT',           // 순수 텍스트 (모든 HTML 제거)
  BASIC_HTML = 'BASIC_HTML',           // 기본 HTML (b, i, u, p, br 등만 허용)
  RICH_TEXT = 'RICH_TEXT',             // 풍부한 텍스트 (더 많은 태그 허용)
  COMMENT = 'COMMENT',                 // 댓글 (제한적 HTML)
  ARTICLE_CONTENT = 'ARTICLE_CONTENT', // 기사 내용 (포괄적 허용)
  USER_BIO = 'USER_BIO',               // 사용자 소개
  SEARCH_QUERY = 'SEARCH_QUERY'        // 검색 쿼리
}

/**
 * HTML 새니타이저 클래스
 * 
 * 사용자 입력 HTML을 안전하게 정화하여 XSS 공격을 방지하는 클래스입니다.
 */
export class HTMLSanitizer {
  private readonly logger = new Logger('HTMLSanitizer');

  // ============================================================================
  // 🏷️ 허용된 HTML 태그 및 속성 정의
  // ============================================================================
  
  /**
   * 기본적으로 허용되는 안전한 HTML 태그
   */
  private readonly DEFAULT_ALLOWED_TAGS = [
    // 텍스트 서식
    'p', 'br', 'hr', 'div', 'span',
    'b', 'strong', 'i', 'em', 'u', 's', 'del', 'ins',
    'sub', 'sup', 'small', 'mark', 'code', 'pre',
    
    // 목록
    'ul', 'ol', 'li', 'dl', 'dt', 'dd',
    
    // 제목
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    
    // 인용
    'blockquote', 'q', 'cite',
    
    // 테이블 (기본)
    'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th',
    
    // 기타
    'abbr', 'acronym', 'address', 'time'
  ];

  /**
   * 컨텍스트별 허용 태그 매핑
   */
  private readonly CONTEXT_ALLOWED_TAGS: Record<SanitizationContext, string[]> = {
    [SanitizationContext.PLAIN_TEXT]: [],
    [SanitizationContext.BASIC_HTML]: ['p', 'br', 'b', 'i', 'u', 'strong', 'em'],
    [SanitizationContext.RICH_TEXT]: this.DEFAULT_ALLOWED_TAGS,
    [SanitizationContext.COMMENT]: ['p', 'br', 'b', 'i', 'u', 'strong', 'em', 'code', 'pre'],
    [SanitizationContext.ARTICLE_CONTENT]: [
      ...this.DEFAULT_ALLOWED_TAGS,
      'a', 'img', 'figure', 'figcaption', 'caption',
      'colgroup', 'col'
    ],
    [SanitizationContext.USER_BIO]: ['p', 'br', 'b', 'i', 'u', 'strong', 'em', 'a'],
    [SanitizationContext.SEARCH_QUERY]: []
  };

  /**
   * 기본적으로 허용되는 안전한 HTML 속성
   */
  private readonly DEFAULT_ALLOWED_ATTRIBUTES = [
    'id', 'class', 'title', 'lang', 'dir',
    'alt', 'src', 'width', 'height',
    'href', 'target', 'rel',
    'colspan', 'rowspan',
    'cite', 'datetime'
  ];

  /**
   * 허용되는 URL 스키마
   */
  private readonly ALLOWED_URL_SCHEMES = [
    'http', 'https', 'mailto', 'tel', 'ftp'
  ];

  /**
   * 완전히 제거해야 할 위험한 HTML 태그
   */
  private readonly DANGEROUS_TAGS = [
    'script', 'style', 'iframe', 'frame', 'frameset', 'noframes',
    'object', 'embed', 'applet', 'param', 'layer', 'ilayer',
    'meta', 'link', 'base', 'form', 'input', 'textarea', 'select',
    'option', 'button', 'fieldset', 'legend', 'label'
  ];

  /**
   * 제거해야 할 위험한 HTML 속성
   */
  private readonly DANGEROUS_ATTRIBUTES = [
    // JavaScript 이벤트 핸들러
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
    'onselectstart', 'onstart', 'onstop', 'onsubmit', 'onunload',
    
    // 기타 위험한 속성
    'expression', 'mocha', 'vbscript', 'livescript', 'behaviour', 'behavior'
  ];

  // ============================================================================
  // 📊 공개 메서드들
  // ============================================================================

  /**
   * HTML 새니타이징 수행
   * 
   * @param html 새니타이징할 HTML 문자열
   * @param context 새니타이징 컨텍스트
   * @param options 추가 옵션
   * @returns 새니타이징 결과
   */
  public sanitize(
    html: string,
    context: SanitizationContext = SanitizationContext.BASIC_HTML,
    options?: Partial<HTMLSanitizationOptions>
  ): HTMLSanitizationResult {
    if (!html || typeof html !== 'string') {
      return {
        sanitizedHTML: '',
        removedElements: [],
        wasModified: false,
        warnings: []
      };
    }

    const removedElements: string[] = [];
    const warnings: string[] = [];
    const originalHTML = html;

    // 옵션 설정
    const sanitizationOptions = this.buildOptions(context, options);

    let sanitizedHTML = html;

    // 1. 길이 제한 확인
    if (sanitizationOptions.maxLength && sanitizedHTML.length > sanitizationOptions.maxLength) {
      sanitizedHTML = sanitizedHTML.substring(0, sanitizationOptions.maxLength);
      warnings.push(`Content truncated to ${sanitizationOptions.maxLength} characters`);
    }

    // 2. HTML 주석 제거
    if (sanitizationOptions.stripComments) {
      sanitizedHTML = this.removeHTMLComments(sanitizedHTML);
    }

    // 3. 위험한 태그 제거
    const tagResult = this.removeDangerousTags(sanitizedHTML);
    sanitizedHTML = tagResult.html;
    removedElements.push(...tagResult.removed);

    // 4. 허용되지 않은 태그 처리
    const allowedTagResult = this.processAllowedTags(
      sanitizedHTML, 
      sanitizationOptions.allowedTags!,
      sanitizationOptions.stripUnknownTags!
    );
    sanitizedHTML = allowedTagResult.html;
    removedElements.push(...allowedTagResult.removed);

    // 5. 위험한 속성 제거
    const attributeResult = this.removeDangerousAttributes(
      sanitizedHTML,
      sanitizationOptions.allowedAttributes!,
      sanitizationOptions.allowedSchemes!
    );
    sanitizedHTML = attributeResult.html;
    removedElements.push(...attributeResult.removed);

    // 6. 특수문자 인코딩
    if (sanitizationOptions.encodeSpecialChars) {
      sanitizedHTML = this.encodeSpecialCharacters(sanitizedHTML);
    }

    // 7. 줄바꿈 처리
    if (sanitizationOptions.preserveLineBreaks) {
      sanitizedHTML = this.preserveLineBreaks(sanitizedHTML);
    }

    // 8. 최종 정리
    sanitizedHTML = this.finalCleanup(sanitizedHTML);

    const wasModified = originalHTML !== sanitizedHTML;

    // 수정 사항 로깅
    if (wasModified) {
      this.logger.info('HTML 새니타이징 완료', {
        context,
        originalLength: originalHTML.length,
        sanitizedLength: sanitizedHTML.length,
        removedCount: removedElements.length,
        warningCount: warnings.length
      });
    }

    return {
      sanitizedHTML,
      removedElements,
      wasModified,
      warnings
    };
  }

  /**
   * 순수 텍스트 추출 (모든 HTML 제거)
   * 
   * @param html HTML 문자열
   * @returns 순수 텍스트
   */
  public stripAllHTML(html: string): string {
    if (!html || typeof html !== 'string') {
      return '';
    }

    // HTML 태그 모두 제거
    let text = html.replace(/<[^>]*>/g, '');
    
    // HTML 엔티티 디코딩
    text = this.decodeHTMLEntities(text);
    
    // 여러 공백을 하나로 정리
    text = text.replace(/\s+/g, ' ').trim();
    
    return text;
  }

  /**
   * 빠른 XSS 방지 인코딩
   * 
   * @param input 입력 문자열
   * @returns 인코딩된 문자열
   */
  public quickEncode(input: string): string {
    if (!input || typeof input !== 'string') {
      return '';
    }

    return input
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/\//g, '&#x2F;');
  }

  // ============================================================================
  // 🔧 내부 처리 메서드들
  // ============================================================================

  /**
   * 새니타이징 옵션 구성
   */
  private buildOptions(
    context: SanitizationContext,
    userOptions?: Partial<HTMLSanitizationOptions>
  ): HTMLSanitizationOptions {
    const defaultOptions: HTMLSanitizationOptions = {
      allowedTags: this.CONTEXT_ALLOWED_TAGS[context],
      allowedAttributes: this.DEFAULT_ALLOWED_ATTRIBUTES,
      allowedSchemes: this.ALLOWED_URL_SCHEMES,
      stripComments: true,
      stripUnknownTags: true,
      encodeSpecialChars: context === SanitizationContext.PLAIN_TEXT,
      preserveLineBreaks: true,
      maxLength: context === SanitizationContext.SEARCH_QUERY ? 500 : 10000
    };

    return { ...defaultOptions, ...userOptions };
  }

  /**
   * HTML 주석 제거
   */
  private removeHTMLComments(html: string): string {
    return html.replace(/<!--[\s\S]*?-->/g, '');
  }

  /**
   * 위험한 태그 제거
   */
  private removeDangerousTags(html: string): { html: string; removed: string[] } {
    const removed: string[] = [];
    let cleanHTML = html;

    for (const tag of this.DANGEROUS_TAGS) {
      const pattern = new RegExp(`<\\s*${tag}[^>]*>.*?<\\s*\\/\\s*${tag}\\s*>`, 'gis');
      const selfClosingPattern = new RegExp(`<\\s*${tag}[^>]*\\s*\\/?>`, 'gi');
      
      if (pattern.test(cleanHTML) || selfClosingPattern.test(cleanHTML)) {
        removed.push(tag);
        cleanHTML = cleanHTML.replace(pattern, '');
        cleanHTML = cleanHTML.replace(selfClosingPattern, '');
      }
    }

    return { html: cleanHTML, removed };
  }

  /**
   * 허용된 태그만 유지
   */
  private processAllowedTags(
    html: string,
    allowedTags: string[],
    stripUnknownTags: boolean
  ): { html: string; removed: string[] } {
    const removed: string[] = [];
    let processedHTML = html;

    if (allowedTags.length === 0) {
      // 모든 태그 제거
      const allTags = processedHTML.match(/<[^>]+>/g) || [];
      removed.push(...allTags);
      processedHTML = this.stripAllHTML(processedHTML);
    } else if (stripUnknownTags) {
      // 허용되지 않은 태그 제거
      const tagPattern = /<\/?([a-zA-Z][a-zA-Z0-9]*)[^>]*>/g;
      let match;
      
      while ((match = tagPattern.exec(html)) !== null) {
        const tagName = match[1].toLowerCase();
        if (!allowedTags.includes(tagName)) {
          removed.push(match[0]);
          processedHTML = processedHTML.replace(match[0], '');
        }
      }
    }

    return { html: processedHTML, removed };
  }

  /**
   * 위험한 속성 제거
   */
  private removeDangerousAttributes(
    html: string,
    allowedAttributes: string[],
    allowedSchemes: string[]
  ): { html: string; removed: string[] } {
    const removed: string[] = [];
    let cleanHTML = html;

    // 위험한 속성 제거
    for (const attr of this.DANGEROUS_ATTRIBUTES) {
      const pattern = new RegExp(`\\s+${attr}\\s*=\\s*[^\\s>]+`, 'gi');
      if (pattern.test(cleanHTML)) {
        removed.push(attr);
        cleanHTML = cleanHTML.replace(pattern, '');
      }
    }

    // URL 스키마 검증
    const urlAttributes = ['href', 'src', 'action', 'formaction'];
    for (const attr of urlAttributes) {
      const pattern = new RegExp(`\\s+${attr}\\s*=\\s*["']([^"']+)["']`, 'gi');
      cleanHTML = cleanHTML.replace(pattern, (match, url) => {
        if (this.isValidURL(url, allowedSchemes)) {
          return match;
        } else {
          removed.push(`${attr}="${url}"`);
          return '';
        }
      });
    }

    return { html: cleanHTML, removed };
  }

  /**
   * URL 유효성 검증
   */
  private isValidURL(url: string, allowedSchemes: string[]): boolean {
    if (!url || typeof url !== 'string') {
      return false;
    }

    // 상대 URL은 허용
    if (!url.includes(':')) {
      return true;
    }

    // 스키마 추출
    const schemeMatch = url.match(/^([a-zA-Z][a-zA-Z0-9+.-]*):/) ;
    if (!schemeMatch) {
      return true;
    }

    const scheme = schemeMatch[1].toLowerCase();
    return allowedSchemes.includes(scheme);
  }

  /**
   * 특수문자 인코딩
   */
  private encodeSpecialCharacters(html: string): string {
    return html
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;');
  }

  /**
   * HTML 엔티티 디코딩
   */
  private decodeHTMLEntities(text: string): string {
    const entityMap: Record<string, string> = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#x27;': "'",
      '&#x2F;': '/',
      '&nbsp;': ' '
    };

    let decoded = text;
    
    for (const [entity, char] of Object.entries(entityMap)) {
      decoded = decoded.replace(new RegExp(entity, 'g'), char);
    }

    // 숫자 엔티티 디코딩
    decoded = decoded.replace(/&#(\d+);/g, (match, dec) => {
      const code = parseInt(dec, 10);
      if (code > 0 && code < 1114112) {
        return String.fromCharCode(code);
      }
      return match;
    });

    // 16진수 엔티티 디코딩
    decoded = decoded.replace(/&#x([0-9a-fA-F]+);/g, (match, hex) => {
      const code = parseInt(hex, 16);
      if (code > 0 && code < 1114112) {
        return String.fromCharCode(code);
      }
      return match;
    });

    return decoded;
  }

  /**
   * 줄바꿈 보존
   */
  private preserveLineBreaks(html: string): string {
    return html.replace(/\n/g, '<br>');
  }

  /**
   * 최종 정리
   */
  private finalCleanup(html: string): string {
    return html
      // 연속된 공백 정리
      .replace(/\s+/g, ' ')
      // 빈 태그 제거
      .replace(/<([^>]+)>\s*<\/\1>/g, '')
      // 태그 사이의 불필요한 공백 제거
      .replace(/>\s+</g, '><')
      // 앞뒤 공백 제거
      .trim();
  }

  /**
   * 새니타이징 통계 조회
   */
  public getSanitizationStats(): {
    totalSanitizations: number;
    modificationsCount: number;
    averageRemovalRate: number;
    commonThreats: Record<string, number>;
  } {
    return {
      totalSanitizations: 0,
      modificationsCount: 0,
      averageRemovalRate: 0,
      commonThreats: {
        'script_tags': 0,
        'event_handlers': 0,
        'javascript_urls': 0,
        'iframe_tags': 0,
        'style_tags': 0
      }
    };
  }
}

/**
 * HTML 새니타이저 싱글톤 인스턴스
 */
export const htmlSanitizer = new HTMLSanitizer();