import 'package:comic_fest/supabase/supabase_config.dart';
import 'package:comic_fest/models/comic_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComicService {
  static final ComicService instance = ComicService._internal();
  final SupabaseClient _client = SupabaseConfig.client;

  ComicService._internal();

  // Generate a new comic
  Future<ComicModel> generateComic(String prompt, {String style = 'comic-book'}) async {
    try {
      final session = _client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
         throw Exception('No hay sesión activa. Por favor inicia sesión nuevamente.');
      }

      final response = await _client.functions.invoke(
        'generate-comic',
        body: {
          'prompt': prompt,
          'style': style,
        },
      );

      if (response.status != 200) {
        throw Exception('Error generating comic: ${response.status}');
      }

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        throw Exception(data['error']);
      }

      return ComicModel.fromJson(data);
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details.containsKey('error')) {
        throw Exception(details['error']);
      }
      throw Exception('Error del servidor: ${e.status} ${e.reasonPhrase ?? ''}');
    } catch (e) {
      throw Exception('Failed to generate comic: $e');
    }
  }

  // Get user's comic history
  Future<List<ComicModel>> getMyComics() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('comics')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => ComicModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch comics: $e');
    }
  }

  // Get user credits
  Future<int> getUserCredits() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('profiles')
          .select('credits')
          .eq('id', userId)
          .single();

      return response['credits'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
