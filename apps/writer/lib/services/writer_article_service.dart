import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_models.dart';
import 'api_service.dart';
import 'storage_service.dart';

class WriterArticleService {
  final ApiService _apiService;
  final StorageService _storageService;

  WriterArticleService(this._apiService, this._storageService);

  // Create a new article
  Future<ArticleResponse> createArticle(CreateArticleRequest request) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _apiService.post(
        '/writer/articles',
        data: request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ArticleResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create article');
        }
      } else {
        final errorData = json.decode(response.body);
        if (errorData['error']?['code'] == 'VALIDATION_ERROR') {
          throw ValidationException(
            errorData['error']['message'] ?? 'Validation failed',
            List<ValidationError>.from(
              errorData['error']['details']['validationErrors']?.map(
                (error) => ValidationError.fromJson(error),
              ) ?? [],
            ),
          );
        }
        throw Exception(errorData['error']?['message'] ?? 'Failed to create article');
      }
    } catch (e) {
      print('Error creating article: $e');
      rethrow;
    }
  }

  // Update an existing article
  Future<ArticleResponse> updateArticle(String articleId, UpdateArticleRequest request) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _apiService.put(
        '/writer/articles/$articleId',
        data: request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ArticleResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update article');
        }
      } else {
        final errorData = json.decode(response.body);
        if (errorData['error']?['code'] == 'VALIDATION_ERROR') {
          throw ValidationException(
            errorData['error']['message'] ?? 'Validation failed',
            List<ValidationError>.from(
              errorData['error']['details']['validationErrors']?.map(
                (error) => ValidationError.fromJson(error),
              ) ?? [],
            ),
          );
        }
        throw Exception(errorData['error']?['message'] ?? 'Failed to update article');
      }
    } catch (e) {
      print('Error updating article: $e');
      rethrow;
    }
  }

  // Get a specific article
  Future<ArticleResponse> getArticle(String articleId) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _apiService.get(
        '/writer/articles/$articleId',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ArticleResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get article');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to get article');
      }
    } catch (e) {
      print('Error getting article: $e');
      rethrow;
    }
  }

  // Get list of articles with pagination and filters
  Future<ArticleListResponse> getArticles({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        '/writer/articles',
        queryParams: queryParams,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ArticleListResponse(
            articles: List<ArticleListItem>.from(
              data['data'].map((article) => ArticleListItem.fromJson(article)),
            ),
            pagination: PaginationInfo.fromJson(data['pagination']),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to get articles');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to get articles');
      }
    } catch (e) {
      print('Error getting articles: $e');
      rethrow;
    }
  }

  // Publish an article
  Future<ArticleResponse> publishArticle(String articleId, {DateTime? publishedAt}) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final requestData = <String, dynamic>{};
      if (publishedAt != null) {
        requestData['publishedAt'] = publishedAt.toIso8601String();
      }

      final response = await _apiService.post(
        '/writer/articles/$articleId/publish',
        data: requestData,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ArticleResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to publish article');
        }
      } else {
        final errorData = json.decode(response.body);
        if (errorData['error']?['code'] == 'VALIDATION_ERROR') {
          throw ValidationException(
            errorData['error']['message'] ?? 'Article validation failed',
            List<ValidationError>.from(
              errorData['error']['details']['validationErrors']?.map(
                (error) => ValidationError.fromJson(error),
              ) ?? [],
            ),
          );
        }
        throw Exception(errorData['error']?['message'] ?? 'Failed to publish article');
      }
    } catch (e) {
      print('Error publishing article: $e');
      rethrow;
    }
  }

  // Unpublish an article
  Future<ArticleResponse> unpublishArticle(String articleId) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _apiService.post(
        '/writer/articles/$articleId/unpublish',
        data: {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ArticleResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to unpublish article');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to unpublish article');
      }
    } catch (e) {
      print('Error unpublishing article: $e');
      rethrow;
    }
  }

  // Delete an article
  Future<void> deleteArticle(String articleId) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _apiService.delete(
        '/writer/articles/$articleId',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete article');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to delete article');
      }
    } catch (e) {
      print('Error deleting article: $e');
      rethrow;
    }
  }

  // Archive an article
  Future<ArticleResponse> archiveArticle(String articleId) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _apiService.post(
        '/writer/articles/$articleId/archive',
        data: {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ArticleResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to archive article');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to archive article');
      }
    } catch (e) {
      print('Error archiving article: $e');
      rethrow;
    }
  }

  // Get writer statistics
  Future<WriterStatsResponse> getWriterStats() async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _apiService.get(
        '/writer/articles/stats',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return WriterStatsResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get writer stats');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to get writer stats');
      }
    } catch (e) {
      print('Error getting writer stats: $e');
      rethrow;
    }
  }

  // Auto-save draft
  Future<void> autoSaveDraft(String articleId, String content) async {
    try {
      final token = await _storageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Update article with new content
      await updateArticle(articleId, UpdateArticleRequest(content: content));
    } catch (e) {
      print('Error auto-saving draft: $e');
      // Don't rethrow auto-save errors to avoid disrupting user experience
    }
  }

  // Save draft locally for offline editing
  Future<void> saveDraftLocally(String articleId, Map<String, dynamic> draftData) async {
    try {
      await _storageService.saveDraft(articleId, draftData);
    } catch (e) {
      print('Error saving draft locally: $e');
    }
  }

  // Get local draft
  Future<Map<String, dynamic>?> getLocalDraft(String articleId) async {
    try {
      return await _storageService.getDraft(articleId);
    } catch (e) {
      print('Error getting local draft: $e');
      return null;
    }
  }

  // Clear local draft
  Future<void> clearLocalDraft(String articleId) async {
    try {
      await _storageService.clearDraft(articleId);
    } catch (e) {
      print('Error clearing local draft: $e');
    }
  }
}

// Custom exceptions
class ValidationException implements Exception {
  final String message;
  final List<ValidationError> errors;

  ValidationException(this.message, this.errors);

  @override
  String toString() => 'ValidationException: $message';
}