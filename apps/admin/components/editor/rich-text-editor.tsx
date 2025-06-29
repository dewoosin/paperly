'use client';

import { useState, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { 
  Bold, 
  Italic, 
  Underline, 
  List, 
  ListOrdered, 
  Link, 
  Image, 
  Quote,
  Code,
  Heading1,
  Heading2,
  Heading3
} from 'lucide-react';

interface RichTextEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export default function RichTextEditor({ value, onChange, placeholder }: RichTextEditorProps) {
  const editorRef = useRef<HTMLDivElement>(null);

  const execCommand = (command: string, value: string = '') => {
    document.execCommand(command, false, value);
    editorRef.current?.focus();
  };

  const handleInput = () => {
    if (editorRef.current) {
      onChange(editorRef.current.innerHTML);
    }
  };

  const insertLink = () => {
    const url = prompt('링크 URL을 입력하세요:');
    if (url) {
      execCommand('createLink', url);
    }
  };

  const insertImage = () => {
    const url = prompt('이미지 URL을 입력하세요:');
    if (url) {
      execCommand('insertImage', url);
    }
  };

  const formatBlock = (tag: string) => {
    execCommand('formatBlock', tag);
  };

  return (
    <div className="border rounded-md">
      {/* 툴바 */}
      <div className="flex flex-wrap gap-1 p-2 border-b bg-muted/50">
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => formatBlock('h1')}
          title="제목 1"
        >
          <Heading1 className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => formatBlock('h2')}
          title="제목 2"
        >
          <Heading2 className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => formatBlock('h3')}
          title="제목 3"
        >
          <Heading3 className="h-4 w-4" />
        </Button>
        
        <div className="w-px h-6 bg-border" />
        
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => execCommand('bold')}
          title="굵게"
        >
          <Bold className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => execCommand('italic')}
          title="기울임"
        >
          <Italic className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => execCommand('underline')}
          title="밑줄"
        >
          <Underline className="h-4 w-4" />
        </Button>
        
        <div className="w-px h-6 bg-border" />
        
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => execCommand('insertUnorderedList')}
          title="목록"
        >
          <List className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => execCommand('insertOrderedList')}
          title="번호 목록"
        >
          <ListOrdered className="h-4 w-4" />
        </Button>
        
        <div className="w-px h-6 bg-border" />
        
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => formatBlock('blockquote')}
          title="인용"
        >
          <Quote className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => execCommand('formatBlock', 'pre')}
          title="코드 블록"
        >
          <Code className="h-4 w-4" />
        </Button>
        
        <div className="w-px h-6 bg-border" />
        
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={insertLink}
          title="링크"
        >
          <Link className="h-4 w-4" />
        </Button>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={insertImage}
          title="이미지"
        >
          <Image className="h-4 w-4" />
        </Button>
      </div>

      {/* 에디터 */}
      <div
        ref={editorRef}
        contentEditable
        className="min-h-[300px] p-4 focus:outline-none prose max-w-none"
        onInput={handleInput}
        dangerouslySetInnerHTML={{ __html: value }}
        style={{ 
          whiteSpace: 'pre-wrap'
        }}
        data-placeholder={placeholder}
      />

      <style jsx>{`
        [contenteditable]:empty:before {
          content: attr(data-placeholder);
          color: #9ca3af;
          pointer-events: none;
        }
        
        [contenteditable] h1 {
          font-size: 2em;
          font-weight: bold;
          margin: 0.67em 0;
        }
        
        [contenteditable] h2 {
          font-size: 1.5em;
          font-weight: bold;
          margin: 0.75em 0;
        }
        
        [contenteditable] h3 {
          font-size: 1.25em;
          font-weight: bold;
          margin: 0.83em 0;
        }
        
        [contenteditable] blockquote {
          border-left: 4px solid #e5e7eb;
          margin: 1em 0;
          padding-left: 1em;
          color: #6b7280;
        }
        
        [contenteditable] pre {
          background-color: #f3f4f6;
          padding: 1em;
          border-radius: 0.375rem;
          overflow-x: auto;
          font-family: monospace;
        }
        
        [contenteditable] ul, [contenteditable] ol {
          margin: 1em 0;
          padding-left: 2em;
        }
        
        [contenteditable] img {
          max-width: 100%;
          height: auto;
          border-radius: 0.375rem;
        }
        
        [contenteditable] a {
          color: #3b82f6;
          text-decoration: underline;
        }
      `}</style>
    </div>
  );
}