import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://oxuqfkhytzgoddqkvstu.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94dXFma2h5dHpnb2RkcWt2c3R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4OTIxNTAsImV4cCI6MjA4MTQ2ODE1MH0.VnReQL8bvG4KGpsbXPGF42kx-mthcnt6LzHydVDVr0s',
    );
  }

  // Get messages for a chat
  static Future<List<ChatMessage>> getMessages(String chatId) async {
    final response = await client
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('timestamp', ascending: true);

    return response.map((data) => ChatMessage.fromJson(data)).toList();
  }

  // Send a message
  static Future<void> sendMessage(ChatMessage message) async {
    await client.from('messages').insert(message.toJson());
  }

  // Create a new chat
  static Future<String> createChat(String title) async {
    final response = await client
        .from('chats')
        .insert({'title': title, 'created_at': DateTime.now().toIso8601String()})
        .select()
        .single();

    return response['id'];
  }

  // Get all chats
  static Future<List<Map<String, dynamic>>> getChats() async {
    final response = await client
        .from('chats')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
