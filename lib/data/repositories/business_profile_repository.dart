import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/business_profile/business_profile_completion.dart';
import '../models/business_profile_model.dart';

class BusinessProfileRepository {
  BusinessProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<BusinessProfileModel?> fetchMyBusinessProfile() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('business_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) {
        return _buildDraftProfile(user);
      }

      return BusinessProfileModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      if (_isBusinessProfilesTableMissing(e)) {
        return _buildDraftProfile(user);
      }
      throw Exception('İşletme profili alınamadı. ${e.message}');
    } catch (_) {
      throw Exception('İşletme profili alınırken bir sorun oluştu.');
    }
  }

  Future<BusinessProfileModel> createBusinessProfile(BusinessProfileModel profile) async {
    try {
      final user = _requireUser();
      final normalized = _normalizeProfile(profile, user.id);
      final payload = normalized.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data =
          await _client.from('business_profiles').insert(payload).select().single();

      return BusinessProfileModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşletme profili oluşturulamadı. ${e.message}');
    } catch (_) {
      throw Exception('İşletme profili oluşturulurken bir sorun oluştu.');
    }
  }

  Future<BusinessProfileModel> upsertBusinessProfile(BusinessProfileModel profile) async {
    try {
      final user = _requireUser();
      final normalized = _normalizeProfile(profile, user.id);
      final payload = normalized.toJson()
        ..remove('created_at')
        ..remove('updated_at');
      if ((payload['id']?.toString().isEmpty ?? true)) {
        payload.remove('id');
      }

      final data = await _client
          .from('business_profiles')
          .upsert(payload, onConflict: 'user_id')
          .select()
          .single();

      return BusinessProfileModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşletme profili kaydedilemedi. ${e.message}');
    } catch (_) {
      throw Exception('İşletme profili kaydedilirken bir sorun oluştu.');
    }
  }

  Future<BusinessProfileModel> updateBusinessProfile(BusinessProfileModel profile) async {
    try {
      final user = _requireUser();
      final normalized = _normalizeProfile(profile, user.id);
      final payload = normalized.toJson()
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _client
          .from('business_profiles')
          .update(payload)
          .eq('user_id', user.id)
          .select()
          .single();

      return BusinessProfileModel.fromJson(data);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşletme profili güncellenemedi. ${e.message}');
    } catch (_) {
      throw Exception('İşletme profili güncellenirken bir sorun oluştu.');
    }
  }

  Future<void> deleteBusinessProfile() async {
    try {
      final user = _requireUser();
      await _client.from('business_profiles').delete().eq('user_id', user.id);
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw Exception('İşletme profili silinemedi. ${e.message}');
    } catch (_) {
      throw Exception('İşletme profili silinirken bir sorun oluştu.');
    }
  }

  Future<int> calculateAndUpdateProfileCompletion() async {
    final profile = await fetchMyBusinessProfile();
    if (profile == null || profile.businessName.trim().isEmpty) {
      return 0;
    }

    final completion = calculateBusinessProfileCompletion(profile);
    await upsertBusinessProfile(
      profile.copyWith(
        profileCompletion: completion,
        onboardingCompleted: completion >= 70,
      ),
    );
    return completion;
  }

  BusinessProfileModel _normalizeProfile(BusinessProfileModel profile, String userId) {
    final normalized = profile.copyWith(
      userId: userId,
      profileCompletion: calculateBusinessProfileCompletion(profile),
      onboardingCompleted: calculateBusinessProfileCompletion(profile) >= 70,
    );

    final metadata = _client.auth.currentUser?.userMetadata;
    final metadataBusinessName = metadata == null
        ? ''
        : metadata['business_name']?.toString().trim() ?? '';

    final businessName = normalized.businessName.trim().isEmpty
        ? metadataBusinessName
        : normalized.businessName.trim();

    return normalized.copyWith(
      businessName: businessName.isEmpty ? 'İşletmem' : businessName,
    );
  }

  BusinessProfileModel? _buildDraftProfile(User user) {
    final businessName = user.userMetadata?['business_name']?.toString().trim() ?? '';
    if (businessName.isEmpty) {
      return null;
    }
    return BusinessProfileModel.empty(
      businessName: businessName,
      userId: user.id,
    );
  }

  bool _isBusinessProfilesTableMissing(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        (message.contains('business_profiles') &&
            (message.contains('could not find the table') ||
                message.contains('schema cache')));
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return user;
  }
}
