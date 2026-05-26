import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collection_reminder_model.dart';

class CollectionRemindersRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<CollectionReminderModel> saveReminder(CollectionReminderModel reminder) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');

    final data = reminder.toJson();
    data['user_id'] = user.id;

    try {
      if (reminder.id.isEmpty) {
        final res = await _supabase.from('collection_reminders').insert(data).select().single();
        return CollectionReminderModel.fromJson(res);
      } else {
        final res = await _supabase
            .from('collection_reminders')
            .update(data)
            .eq('id', reminder.id)
            .eq('user_id', user.id)
            .select()
            .single();
        return CollectionReminderModel.fromJson(res);
      }
    } catch (e) {
      throw Exception('Tahsilat mesajı kaydedilemedi: $e');
    }
  }

  Future<void> updateStatus(String reminderId, String status) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('collection_reminders')
        .update({'status': status})
        .eq('id', reminderId)
        .eq('user_id', user.id);
  }
}