'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuLabel, 
  DropdownMenuSeparator, 
  DropdownMenuTrigger 
} from '@/components/ui/dropdown-menu';
import { 
  Search, 
  Plus, 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  Eye, 
  CheckCircle2, 
  XCircle 
} from 'lucide-react';
import { format } from 'date-fns';
import { ko } from 'date-fns/locale';

interface Article {
  id: string;
  title: string;
  slug: string;
  author_name: string;
  category: {
    id: string;
    name: string;
  };
  status: string;
  is_featured: boolean;
  is_premium: boolean;
  view_count: number;
  published_at: string | null;
  created_at: string;
}

const statusColors = {
  draft: 'secondary',
  review: 'warning',
  published: 'success',
  archived: 'muted',
  deleted: 'destructive'
} as const;

const statusLabels = {
  draft: '임시저장',
  review: '검토중',
  published: '게시됨',
  archived: '보관됨',
  deleted: '삭제됨'
} as const;

export default function ArticlesPage() {
  const router = useRouter();
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    fetchArticles();
  }, [page, statusFilter, search]);

  const fetchArticles = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: '20',
        ...(statusFilter !== 'all' && { status: statusFilter }),
        ...(search && { search })
      });

      const response = await fetch(`/api/admin/articles?${params}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        }
      });

      if (!response.ok) throw new Error('Failed to fetch articles');

      const data = await response.json();
      setArticles(data.data);
      setTotalPages(data.pagination.totalPages);
    } catch (error) {
      console.error('Error fetching articles:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string, permanent: boolean = false) => {
    if (!confirm(permanent ? '정말로 영구 삭제하시겠습니까?' : '휴지통으로 이동하시겠습니까?')) {
      return;
    }

    try {
      const response = await fetch(`/api/admin/articles/${id}?permanent=${permanent}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        }
      });

      if (!response.ok) throw new Error('Failed to delete article');

      fetchArticles();
    } catch (error) {
      console.error('Error deleting article:', error);
    }
  };

  const handlePublish = async (id: string) => {
    try {
      const response = await fetch(`/api/admin/articles/${id}/publish`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        }
      });

      if (!response.ok) throw new Error('Failed to publish article');

      fetchArticles();
    } catch (error) {
      console.error('Error publishing article:', error);
    }
  };

  const handleUnpublish = async (id: string) => {
    try {
      const response = await fetch(`/api/admin/articles/${id}/unpublish`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
        }
      });

      if (!response.ok) throw new Error('Failed to unpublish article');

      fetchArticles();
    } catch (error) {
      console.error('Error unpublishing article:', error);
    }
  };

  return (
    <div className="container mx-auto py-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold">기사 관리</h1>
          <p className="text-muted-foreground">모든 기사를 관리하고 편집할 수 있습니다</p>
        </div>
        <Button onClick={() => router.push('/articles/new')}>
          <Plus className="mr-2 h-4 w-4" />
          새 기사 작성
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex gap-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
                <Input
                  placeholder="제목, 내용으로 검색..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-8"
                />
              </div>
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="상태 필터" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">모든 상태</SelectItem>
                <SelectItem value="draft">임시저장</SelectItem>
                <SelectItem value="review">검토중</SelectItem>
                <SelectItem value="published">게시됨</SelectItem>
                <SelectItem value="archived">보관됨</SelectItem>
                <SelectItem value="deleted">삭제됨</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8">로딩중...</div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>제목</TableHead>
                    <TableHead>작성자</TableHead>
                    <TableHead>카테고리</TableHead>
                    <TableHead>상태</TableHead>
                    <TableHead>조회수</TableHead>
                    <TableHead>작성일</TableHead>
                    <TableHead>게시일</TableHead>
                    <TableHead className="text-right">액션</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {articles.map((article) => (
                    <TableRow key={article.id}>
                      <TableCell className="font-medium">
                        <div>
                          {article.title}
                          <div className="flex gap-2 mt-1">
                            {article.is_featured && (
                              <Badge variant="default" className="text-xs">추천</Badge>
                            )}
                            {article.is_premium && (
                              <Badge variant="secondary" className="text-xs">프리미엄</Badge>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{article.author_name}</TableCell>
                      <TableCell>{article.category?.name || '-'}</TableCell>
                      <TableCell>
                        <Badge variant={statusColors[article.status as keyof typeof statusColors] || 'default'}>
                          {statusLabels[article.status as keyof typeof statusLabels] || article.status}
                        </Badge>
                      </TableCell>
                      <TableCell>{article.view_count.toLocaleString()}</TableCell>
                      <TableCell>
                        {format(new Date(article.created_at), 'yyyy.MM.dd', { locale: ko })}
                      </TableCell>
                      <TableCell>
                        {article.published_at 
                          ? format(new Date(article.published_at), 'yyyy.MM.dd', { locale: ko })
                          : '-'
                        }
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0">
                              <span className="sr-only">메뉴 열기</span>
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuLabel>액션</DropdownMenuLabel>
                            <DropdownMenuItem 
                              onClick={() => window.open(`/articles/${article.slug}`, '_blank')}
                            >
                              <Eye className="mr-2 h-4 w-4" />
                              미리보기
                            </DropdownMenuItem>
                            <DropdownMenuItem 
                              onClick={() => router.push(`/articles/${article.id}/edit`)}
                            >
                              <Edit className="mr-2 h-4 w-4" />
                              편집
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            {article.status === 'published' ? (
                              <DropdownMenuItem onClick={() => handleUnpublish(article.id)}>
                                <XCircle className="mr-2 h-4 w-4" />
                                게시 취소
                              </DropdownMenuItem>
                            ) : article.status === 'draft' || article.status === 'review' ? (
                              <DropdownMenuItem onClick={() => handlePublish(article.id)}>
                                <CheckCircle2 className="mr-2 h-4 w-4" />
                                게시하기
                              </DropdownMenuItem>
                            ) : null}
                            <DropdownMenuSeparator />
                            {article.status !== 'deleted' ? (
                              <DropdownMenuItem 
                                onClick={() => handleDelete(article.id)}
                                className="text-destructive"
                              >
                                <Trash2 className="mr-2 h-4 w-4" />
                                휴지통으로
                              </DropdownMenuItem>
                            ) : (
                              <DropdownMenuItem 
                                onClick={() => handleDelete(article.id, true)}
                                className="text-destructive"
                              >
                                <Trash2 className="mr-2 h-4 w-4" />
                                영구 삭제
                              </DropdownMenuItem>
                            )}
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>

              {totalPages > 1 && (
                <div className="flex justify-center gap-2 mt-4">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage(page - 1)}
                    disabled={page === 1}
                  >
                    이전
                  </Button>
                  <span className="flex items-center px-4">
                    {page} / {totalPages}
                  </span>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage(page + 1)}
                    disabled={page === totalPages}
                  >
                    다음
                  </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}