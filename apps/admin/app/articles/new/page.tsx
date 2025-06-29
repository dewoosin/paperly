'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { AlertCircle, Save, ArrowLeft, Image as ImageIcon, X } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import dynamic from 'next/dynamic';

// 동적으로 에디터 로드 (SSR 방지)
const Editor = dynamic(() => import('@/components/editor/rich-text-editor'), {
  ssr: false,
  loading: () => <div className="h-96 bg-muted animate-pulse rounded-md" />
});

interface Category {
  id: string;
  name: string;
  slug: string;
}

interface Tag {
  id: string;
  name: string;
  display_name: string;
}

export default function NewArticlePage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [categories, setCategories] = useState<Category[]>([]);
  const [allTags, setAllTags] = useState<Tag[]>([]);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [tagSearch, setTagSearch] = useState('');
  
  // 폼 데이터
  const [formData, setFormData] = useState({
    title: '',
    slug: '',
    summary: '',
    content: '',
    category_id: '',
    featured_image_url: '',
    status: 'draft',
    is_featured: false,
    is_premium: false,
    difficulty_level: 1,
    content_type: 'article',
    seo_title: '',
    seo_description: '',
    seo_keywords: [] as string[]
  });

  useEffect(() => {
    fetchCategories();
    fetchTags();
  }, []);

  useEffect(() => {
    // 제목이 변경되면 자동으로 slug 생성
    if (formData.title && !formData.slug) {
      const slug = formData.title
        .toLowerCase()
        .replace(/[^\w\s가-힣-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/--+/g, '-')
        .trim();
      setFormData(prev => ({ ...prev, slug }));
    }
  }, [formData.title]);

  const fetchCategories = async () => {
    try {
      const response = await fetch('/api/admin/articles/categories', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        }
      });
      const data = await response.json();
      setCategories(data.data);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const fetchTags = async (search = '') => {
    try {
      const params = new URLSearchParams();
      if (search) params.append('search', search);
      
      const response = await fetch(`/api/admin/articles/tags?${params}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        }
      });
      const data = await response.json();
      setAllTags(data.data);
    } catch (error) {
      console.error('Error fetching tags:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await fetch('/api/admin/articles', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        },
        body: JSON.stringify({
          ...formData,
          tags: selectedTags
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to create article');
      }

      const data = await response.json();
      router.push('/articles');
    } catch (error: any) {
      setError(error.message || '기사 작성 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  const handleTagToggle = (tagId: string) => {
    setSelectedTags(prev => 
      prev.includes(tagId) 
        ? prev.filter(id => id !== tagId)
        : [...prev, tagId]
    );
  };

  const handleTagSearch = (value: string) => {
    setTagSearch(value);
    if (value) {
      fetchTags(value);
    }
  };

  return (
    <div className="container mx-auto py-6">
      <div className="mb-6">
        <Button
          variant="ghost"
          onClick={() => router.back()}
          className="mb-4"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          뒤로가기
        </Button>
        <h1 className="text-3xl font-bold">새 기사 작성</h1>
        <p className="text-muted-foreground">새로운 기사를 작성하고 발행할 수 있습니다</p>
      </div>

      {error && (
        <Alert variant="destructive" className="mb-6">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <form onSubmit={handleSubmit}>
        <div className="grid gap-6 lg:grid-cols-3">
          {/* 메인 콘텐츠 영역 */}
          <div className="lg:col-span-2 space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>기본 정보</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="title">제목 *</Label>
                  <Input
                    id="title"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    placeholder="기사 제목을 입력하세요"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="slug">슬러그 (URL)</Label>
                  <Input
                    id="slug"
                    value={formData.slug}
                    onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                    placeholder="url-friendly-slug"
                  />
                  <p className="text-sm text-muted-foreground">
                    URL에 사용될 경로입니다. 영문, 숫자, 하이픈만 사용 가능합니다.
                  </p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="summary">요약 *</Label>
                  <Textarea
                    id="summary"
                    value={formData.summary}
                    onChange={(e) => setFormData({ ...formData, summary: e.target.value })}
                    placeholder="기사의 간단한 요약을 작성하세요 (50-500자)"
                    rows={3}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="content">본문 *</Label>
                  <Editor
                    value={formData.content}
                    onChange={(value) => setFormData({ ...formData, content: value })}
                    placeholder="기사 내용을 작성하세요..."
                  />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>SEO 설정</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="seo_title">SEO 제목</Label>
                  <Input
                    id="seo_title"
                    value={formData.seo_title}
                    onChange={(e) => setFormData({ ...formData, seo_title: e.target.value })}
                    placeholder="검색 결과에 표시될 제목 (기본: 기사 제목)"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="seo_description">SEO 설명</Label>
                  <Textarea
                    id="seo_description"
                    value={formData.seo_description}
                    onChange={(e) => setFormData({ ...formData, seo_description: e.target.value })}
                    placeholder="검색 결과에 표시될 설명 (기본: 기사 요약)"
                    rows={2}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="seo_keywords">SEO 키워드</Label>
                  <Input
                    id="seo_keywords"
                    placeholder="키워드를 쉼표로 구분하여 입력"
                    onKeyPress={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        const input = e.currentTarget;
                        const keywords = input.value.split(',').map(k => k.trim()).filter(k => k);
                        setFormData({ ...formData, seo_keywords: [...formData.seo_keywords, ...keywords] });
                        input.value = '';
                      }
                    }}
                  />
                  <div className="flex flex-wrap gap-2 mt-2">
                    {formData.seo_keywords.map((keyword, index) => (
                      <Badge key={index} variant="secondary">
                        {keyword}
                        <button
                          type="button"
                          onClick={() => {
                            setFormData({
                              ...formData,
                              seo_keywords: formData.seo_keywords.filter((_, i) => i !== index)
                            });
                          }}
                          className="ml-1"
                        >
                          <X className="h-3 w-3" />
                        </button>
                      </Badge>
                    ))}
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* 사이드바 영역 */}
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>발행 설정</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="status">상태</Label>
                  <Select
                    value={formData.status}
                    onValueChange={(value) => setFormData({ ...formData, status: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="draft">임시저장</SelectItem>
                      <SelectItem value="review">검토중</SelectItem>
                      <SelectItem value="published">게시</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="category">카테고리 *</Label>
                  <Select
                    value={formData.category_id}
                    onValueChange={(value) => setFormData({ ...formData, category_id: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="카테고리 선택" />
                    </SelectTrigger>
                    <SelectContent>
                      {categories.map((category) => (
                        <SelectItem key={category.id} value={category.id}>
                          {category.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="content_type">콘텐츠 유형</Label>
                  <Select
                    value={formData.content_type}
                    onValueChange={(value) => setFormData({ ...formData, content_type: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="article">일반 기사</SelectItem>
                      <SelectItem value="series">시리즈</SelectItem>
                      <SelectItem value="tutorial">튜토리얼</SelectItem>
                      <SelectItem value="opinion">오피니언</SelectItem>
                      <SelectItem value="news">뉴스</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="difficulty_level">난이도</Label>
                  <Select
                    value={formData.difficulty_level.toString()}
                    onValueChange={(value) => setFormData({ ...formData, difficulty_level: parseInt(value) })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="1">⭐ 매우 쉬움</SelectItem>
                      <SelectItem value="2">⭐⭐ 쉬움</SelectItem>
                      <SelectItem value="3">⭐⭐⭐ 보통</SelectItem>
                      <SelectItem value="4">⭐⭐⭐⭐ 어려움</SelectItem>
                      <SelectItem value="5">⭐⭐⭐⭐⭐ 매우 어려움</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>추가 옵션</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <Label htmlFor="is_featured">추천 기사</Label>
                  <Switch
                    id="is_featured"
                    checked={formData.is_featured}
                    onCheckedChange={(checked) => setFormData({ ...formData, is_featured: checked })}
                  />
                </div>

                <div className="flex items-center justify-between">
                  <Label htmlFor="is_premium">프리미엄 콘텐츠</Label>
                  <Switch
                    id="is_premium"
                    checked={formData.is_premium}
                    onCheckedChange={(checked) => setFormData({ ...formData, is_premium: checked })}
                  />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>대표 이미지</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <Label htmlFor="featured_image_url">이미지 URL</Label>
                  <Input
                    id="featured_image_url"
                    type="url"
                    value={formData.featured_image_url}
                    onChange={(e) => setFormData({ ...formData, featured_image_url: e.target.value })}
                    placeholder="https://example.com/image.jpg"
                  />
                  {formData.featured_image_url && (
                    <div className="mt-2">
                      <img
                        src={formData.featured_image_url}
                        alt="Featured"
                        className="w-full h-32 object-cover rounded-md"
                        onError={(e) => {
                          e.currentTarget.style.display = 'none';
                        }}
                      />
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>태그</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <Input
                    placeholder="태그 검색..."
                    value={tagSearch}
                    onChange={(e) => handleTagSearch(e.target.value)}
                  />
                  <div className="max-h-48 overflow-y-auto space-y-1">
                    {allTags.map((tag) => (
                      <label
                        key={tag.id}
                        className="flex items-center p-2 hover:bg-muted rounded cursor-pointer"
                      >
                        <input
                          type="checkbox"
                          checked={selectedTags.includes(tag.id)}
                          onChange={() => handleTagToggle(tag.id)}
                          className="mr-2"
                        />
                        {tag.display_name}
                      </label>
                    ))}
                  </div>
                </div>
              </CardContent>
            </Card>

            <div className="flex gap-2">
              <Button
                type="submit"
                className="flex-1"
                disabled={loading}
              >
                <Save className="mr-2 h-4 w-4" />
                {loading ? '저장 중...' : '저장'}
              </Button>
              <Button
                type="button"
                variant="outline"
                onClick={() => router.back()}
                disabled={loading}
              >
                취소
              </Button>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}