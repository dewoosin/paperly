// /Users/workspace/paperly/apps/backend/src/presentation/controllers/article.controller.ts

import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../guards/jwt-auth.guard';
import { RolesGuard } from '../guards/roles.guard';
import { Roles } from '../decorators/roles.decorator';
import { ArticleService, CreateArticleRequest, UpdateArticleRequest, ArticleSearchOptions } from '../../application/services/article.service';
import { ArticleStatus } from '../../domain/entities/article.entity';

@ApiTags('articles')
@Controller('articles')
export class ArticleController {
  constructor(private readonly articleService: ArticleService) {}

  @Get()
  @ApiOperation({ summary: '기사 목록 조회' })
  @ApiResponse({ status: 200, description: '기사 목록을 성공적으로 조회했습니다.' })
  async getArticles(@Query() query: any) {
    const options: ArticleSearchOptions = {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      status: query.status as ArticleStatus,
      categoryId: query.categoryId,
      authorId: query.authorId,
      featured: query.featured === 'true',
      trending: query.trending === 'true',
      query: query.search,
    };

    return this.articleService.getArticles(options);
  }

  @Get('published')
  @ApiOperation({ summary: '발행된 기사 목록 조회' })
  @ApiResponse({ status: 200, description: '발행된 기사 목록을 성공적으로 조회했습니다.' })
  async getPublishedArticles(@Query() query: any) {
    const options: Omit<ArticleSearchOptions, 'status'> = {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      categoryId: query.categoryId,
      authorId: query.authorId,
      featured: query.featured === 'true',
      trending: query.trending === 'true',
      query: query.search,
    };

    return this.articleService.getPublishedArticles(options);
  }

  @Get('featured')
  @ApiOperation({ summary: '추천 기사 목록 조회' })
  @ApiResponse({ status: 200, description: '추천 기사 목록을 성공적으로 조회했습니다.' })
  async getFeaturedArticles(@Query('limit') limit?: string) {
    const limitNum = limit ? parseInt(limit) : 5;
    const articles = await this.articleService.getFeaturedArticles(limitNum);
    return { articles };
  }

  @Get('trending')
  @ApiOperation({ summary: '인기 기사 목록 조회' })
  @ApiResponse({ status: 200, description: '인기 기사 목록을 성공적으로 조회했습니다.' })
  async getTrendingArticles(@Query('limit') limit?: string) {
    const limitNum = limit ? parseInt(limit) : 10;
    const articles = await this.articleService.getTrendingArticles(limitNum);
    return { articles };
  }

  @Get('search')
  @ApiOperation({ summary: '기사 검색' })
  @ApiResponse({ status: 200, description: '기사 검색을 성공적으로 완료했습니다.' })
  async searchArticles(@Query() query: any) {
    const options: Omit<ArticleSearchOptions, 'query'> = {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      categoryId: query.categoryId,
      authorId: query.authorId,
    };

    return this.articleService.searchArticles(query.q, options);
  }

  @Get(':id')
  @ApiOperation({ summary: '기사 상세 조회' })
  @ApiResponse({ status: 200, description: '기사를 성공적으로 조회했습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async getArticleById(@Param('id') id: string) {
    const article = await this.articleService.getArticleById(id);
    return { article: article.toResponse() };
  }

  @Get('slug/:slug')
  @ApiOperation({ summary: '슬러그로 기사 조회' })
  @ApiResponse({ status: 200, description: '기사를 성공적으로 조회했습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async getArticleBySlug(@Param('slug') slug: string) {
    const article = await this.articleService.getArticleBySlug(slug);
    return { article: article.toResponse() };
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('author', 'editor', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: '새 기사 작성' })
  @ApiResponse({ status: 201, description: '기사가 성공적으로 작성되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  async createArticle(@Body() createArticleDto: CreateArticleRequest, @Request() req: any) {
    const article = await this.articleService.createArticle(createArticleDto, req.user.id);
    return { article: article.toResponse() };
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '기사 수정' })
  @ApiResponse({ status: 200, description: '기사가 성공적으로 수정되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async updateArticle(
    @Param('id') id: string,
    @Body() updateArticleDto: UpdateArticleRequest,
    @Request() req: any,
  ) {
    const article = await this.articleService.updateArticle(id, updateArticleDto, req.user.id);
    return { article: article.toResponse() };
  }

  @Patch(':id/publish')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('editor', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: '기사 발행' })
  @ApiResponse({ status: 200, description: '기사가 성공적으로 발행되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async publishArticle(@Param('id') id: string, @Request() req: any) {
    const article = await this.articleService.publishArticle(id, req.user.id);
    return { article: article.toResponse() };
  }

  @Patch(':id/unpublish')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('editor', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: '기사 발행 취소' })
  @ApiResponse({ status: 200, description: '기사 발행이 성공적으로 취소되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async unpublishArticle(@Param('id') id: string, @Request() req: any) {
    const article = await this.articleService.unpublishArticle(id, req.user.id);
    return { article: article.toResponse() };
  }

  @Patch(':id/archive')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '기사 보관' })
  @ApiResponse({ status: 200, description: '기사가 성공적으로 보관되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async archiveArticle(@Param('id') id: string, @Request() req: any) {
    const article = await this.articleService.archiveArticle(id, req.user.id);
    return { article: article.toResponse() };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '기사 삭제 (소프트 삭제)' })
  @ApiResponse({ status: 204, description: '기사가 성공적으로 삭제되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async deleteArticle(@Param('id') id: string, @Request() req: any) {
    await this.articleService.deleteArticle(id, req.user.id);
  }

  @Patch(':id/restore')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: '삭제된 기사 복원' })
  @ApiResponse({ status: 200, description: '기사가 성공적으로 복원되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async restoreArticle(@Param('id') id: string, @Request() req: any) {
    const article = await this.articleService.restoreArticle(id, req.user.id);
    return { article: article.toResponse() };
  }

  @Patch(':id/feature')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('editor', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: '기사를 추천 기사로 설정' })
  @ApiResponse({ status: 200, description: '기사가 성공적으로 추천 기사로 설정되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async featureArticle(@Param('id') id: string, @Request() req: any) {
    const article = await this.articleService.featureArticle(id, req.user.id);
    return { article: article.toResponse() };
  }

  @Patch(':id/unfeature')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('editor', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: '추천 기사 설정 해제' })
  @ApiResponse({ status: 200, description: '추천 기사 설정이 성공적으로 해제되었습니다.' })
  @ApiResponse({ status: 401, description: '인증이 필요합니다.' })
  @ApiResponse({ status: 403, description: '권한이 없습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async unfeatureArticle(@Param('id') id: string, @Request() req: any) {
    const article = await this.articleService.unfeatureArticle(id, req.user.id);
    return { article: article.toResponse() };
  }

  @Patch(':id/like')
  @ApiOperation({ summary: '기사 좋아요' })
  @ApiResponse({ status: 200, description: '기사에 좋아요를 성공적으로 표시했습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async likeArticle(@Param('id') id: string) {
    const article = await this.articleService.likeArticle(id);
    return { article: article.toResponse() };
  }

  @Patch(':id/share')
  @ApiOperation({ summary: '기사 공유' })
  @ApiResponse({ status: 200, description: '기사 공유 수가 성공적으로 증가했습니다.' })
  @ApiResponse({ status: 404, description: '기사를 찾을 수 없습니다.' })
  async shareArticle(@Param('id') id: string) {
    const article = await this.articleService.shareArticle(id);
    return { article: article.toResponse() };
  }

  @Get('author/:authorId')
  @ApiOperation({ summary: '작가별 기사 목록 조회' })
  @ApiResponse({ status: 200, description: '작가의 기사 목록을 성공적으로 조회했습니다.' })
  async getArticlesByAuthor(@Param('authorId') authorId: string, @Query() query: any) {
    const options: Omit<ArticleSearchOptions, 'authorId'> = {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      status: query.status as ArticleStatus,
      categoryId: query.categoryId,
      featured: query.featured === 'true',
      trending: query.trending === 'true',
      query: query.search,
    };

    return this.articleService.getArticlesByAuthor(authorId, options);
  }

  @Get('category/:categoryId')
  @ApiOperation({ summary: '카테고리별 기사 목록 조회' })
  @ApiResponse({ status: 200, description: '카테고리의 기사 목록을 성공적으로 조회했습니다.' })
  async getArticlesByCategory(@Param('categoryId') categoryId: string, @Query() query: any) {
    const options: Omit<ArticleSearchOptions, 'categoryId'> = {
      page: parseInt(query.page) || 1,
      limit: parseInt(query.limit) || 20,
      status: query.status as ArticleStatus,
      authorId: query.authorId,
      featured: query.featured === 'true',
      trending: query.trending === 'true',
      query: query.search,
    };

    return this.articleService.getArticlesByCategory(categoryId, options);
  }
}