import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/partner_presence.dart';

/// Handles all Supabase operations: Auth, Rooms, Realtime.
class SupabaseService {
  SupabaseService._();

  static bool get isInitialized {
    try {
      // ignore: unnecessary_null_comparison
      return Supabase.instance.client != null;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser {
    if (!isInitialized) return null;
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }
  static bool get isLoggedIn => currentUser != null;

  // ─── Initialization ────────────────────────────────
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.publishableKey,
    );
  }

  // ─── Auth ──────────────────────────────────────────
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
    return res;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ─── Profile ───────────────────────────────────────
  static Future<void> upsertProfile({
    required String displayName,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  // ─── Rooms ─────────────────────────────────────────
  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static Future<Map<String, dynamic>> createRoom({
    List<String>? categories,
    int roundSize = 10,
  }) async {
    final code = _generateRoomCode();
    final userId = currentUser?.id;

    final room = await client.from('game_rooms').insert({
      'room_code': code,
      'status': 'waiting',
      'host_id': userId,
      'selected_categories': categories ?? [],
      'round_size': roundSize,
    }).select().single();

    return room;
  }

  static Future<Map<String, dynamic>?> joinRoom(String code) async {
    try {
      final room = await client
          .from('game_rooms')
          .select()
          .eq('room_code', code.toUpperCase())
          .eq('status', 'waiting')
          .maybeSingle();

      if (room == null) return null;

      final userId = currentUser?.id;
      await client.from('game_rooms').update({
        'guest_id': userId,
        'status': 'playing',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', room['id']);

      return room;
    } catch (e) {
      debugPrint('Join room error: $e');
      return null;
    }
  }

  static Future<void> updateRoomStatus(String roomId, String status) async {
    await client.from('game_rooms').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId);
  }

  /// Subscribe to room changes via Realtime (basic).
  static RealtimeChannel subscribeToRoom(
    String roomId,
    void Function(Map<String, dynamic> payload) onEvent,
  ) {
    final channel = client.channel('room:$roomId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            onEvent(payload.newRecord);
          },
        )
        .subscribe();
    return channel;
  }

  /// Subscribe to room changes with Realtime Presence tracking, connection status, and broadcast events.
  static RealtimeChannel? subscribeToRoomWithPresence({
    required String roomId,
    required bool isHost,
    required void Function(Map<String, dynamic> payload) onEvent,
    required void Function(RealtimeSubscribeStatus status) onConnectionStatus,
    required void Function(List<PartnerPresence> activePresences)
        onPresenceChange,
    void Function(Map<String, dynamic> payload)? onReaction,
    void Function(String mode)? onGameModeChange,
    void Function(Map<String, dynamic> payload)? onKnowMeAction,
    void Function(Map<String, dynamic> payload)? onGuessWhoAction,
  }) {
    if (!isInitialized) return null;

    final channel = client.channel(
      'room:$roomId',
      opts: const RealtimeChannelConfig(self: true),
    );

    // 1. Table events (cards, steps, actions)
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'room_events',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        onEvent(payload.newRecord);
      },
    );

    // 2. Broadcast events (live floating emoji reactions)
    if (onReaction != null) {
      channel.onBroadcast(
        event: 'reaction',
        callback: (payload) {
          onReaction(payload);
        },
      );
    }

    // 3. Broadcast events: Game Mode Change
    if (onGameModeChange != null) {
      channel.onBroadcast(
        event: 'game_mode_change',
        callback: (payload) {
          final mode = payload['mode']?.toString();
          if (mode != null) onGameModeChange(mode);
        },
      );
    }

    // 4. Broadcast events: Know Me Game Actions
    if (onKnowMeAction != null) {
      channel.onBroadcast(
        event: 'know_me_action',
        callback: (payload) {
          onKnowMeAction(payload);
        },
      );
    }

    // 5. Broadcast events: Guess Who Game Actions
    if (onGuessWhoAction != null) {
      channel.onBroadcast(
        event: 'guess_who_action',
        callback: (payload) {
          onGuessWhoAction(payload);
        },
      );
    }

    void parsePresences() {
      try {
        final presences = <PartnerPresence>[];
        final dynamic rawState = channel.presenceState();
        if (rawState is Map) {
          for (final entry in rawState.entries) {
            final val = entry.value;
            if (val is Iterable) {
              for (final item in val) {
                final payload = (item as dynamic).payload;
                if (payload is Map<String, dynamic>) {
                  presences.add(PartnerPresence.fromJson(payload));
                } else if (payload is Map) {
                  presences.add(
                    PartnerPresence.fromJson(Map<String, dynamic>.from(payload)),
                  );
                }
              }
            }
          }
        } else if (rawState is Iterable) {
          for (final item in rawState) {
            final payload = (item as dynamic).payload;
            if (payload is Map<String, dynamic>) {
              presences.add(PartnerPresence.fromJson(payload));
            } else if (payload is Map) {
              presences.add(
                PartnerPresence.fromJson(Map<String, dynamic>.from(payload)),
              );
            }
          }
        }
        onPresenceChange(presences);
      } catch (e) {
        debugPrint('Error parsing realtime presence: $e');
      }
    }

    // 2. Realtime Presence callbacks
    channel.onPresenceSync((_) => parsePresences());
    channel.onPresenceJoin((_) => parsePresences());
    channel.onPresenceLeave((_) => parsePresences());

    // 3. Subscribe channel & track current user presence
    channel.subscribe((status, [error]) async {
      onConnectionStatus(status);
      if (status == RealtimeSubscribeStatus.subscribed) {
        final user = currentUser;
        final role = isHost ? 'host' : 'guest';
        final displayName =
            user?.email?.split('@').first ?? (isHost ? 'المضيف' : 'الشريك');
        try {
          await channel.track({
            'user_id': user?.id ?? 'anon',
            'role': role,
            'display_name': displayName,
            'last_seen': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Error tracking presence on subscribe: $e');
        }
      }
    });

    return channel;
  }

  static Future<void> sendRoomEvent({
    required String roomId,
    required String eventType,
    required String actorRole,
    String? cardId,
    Map<String, dynamic>? data,
  }) async {
    await client.from('room_events').insert({
      'room_id': roomId,
      'event_type': eventType,
      'actor_role': actorRole,
      if (cardId != null) 'card_id': cardId,
      if (data != null) 'event_data': data,
    });
  }

  /// Broadcast a live reaction emoji directly to room participants via WebSockets.
  static Future<void> sendReaction({
    required RealtimeChannel channel,
    required String emoji,
    required String actorRole,
    String? actorName,
  }) async {
    try {
      await channel.sendBroadcastMessage(
        event: 'reaction',
        payload: {
          'emoji': emoji,
          'sender_role': actorRole,
          'sender_name':
              actorName ?? (actorRole == 'host' ? 'المضيف' : 'الشريك'),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Error sending reaction broadcast: $e');
    }
  }

  /// Broadcast game mode change (cards, knowMe, guessWho).
  static Future<void> sendGameModeChange({
    required RealtimeChannel channel,
    required String mode,
    required String actorRole,
  }) async {
    try {
      await channel.sendBroadcastMessage(
        event: 'game_mode_change',
        payload: {
          'mode': mode,
          'actor_role': actorRole,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Error broadcasting game mode change: $e');
    }
  }

  /// Broadcast Know-Me game action (secret submitted, guess submitted, score, etc.)
  static Future<void> sendKnowMeAction({
    required RealtimeChannel channel,
    required String action,
    required String actorRole,
    Map<String, dynamic>? data,
  }) async {
    try {
      await channel.sendBroadcastMessage(
        event: 'know_me_action',
        payload: {
          'action': action,
          'actor_role': actorRole,
          'data': data ?? {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Error broadcasting Know-Me action: $e');
    }
  }

  /// Broadcast Guess-Who game action (picked secret, ask question, answer, final guess, restart)
  static Future<void> sendGuessWhoAction({
    required RealtimeChannel channel,
    required String action,
    required String actorRole,
    Map<String, dynamic>? data,
  }) async {
    try {
      await channel.sendBroadcastMessage(
        event: 'guess_who_action',
        payload: {
          'action': action,
          'actor_role': actorRole,
          'data': data ?? {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Error broadcasting Guess-Who action: $e');
    }
  }

  static Future<void> unsubscribeFromRoom(RealtimeChannel channel) async {
    try {
      await channel.untrack();
    } catch (_) {}
    await client.removeChannel(channel);
  }

  /// Cleanly leaves the room by untracking presence and removing channel.
  static Future<void> leaveRoom({
    required RealtimeChannel channel,
    required String roomId,
    required String actorRole,
  }) async {
    try {
      await channel.untrack();
    } catch (_) {}
    try {
      await client.removeChannel(channel);
    } catch (_) {}
  }

  // ─── Favorites Sync ────────────────────────────────
  static Future<void> syncFavorites(Set<String> localFavorites) async {
    if (!isLoggedIn) return;
    try {
      await client.from('user_favorites').upsert({
        'user_id': currentUser!.id,
        'card_ids': localFavorites.toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silently fail — offline-first approach
    }
  }

  static Future<Set<String>> fetchFavorites() async {
    if (!isLoggedIn) return {};
    try {
      final data = await client
          .from('user_favorites')
          .select('card_ids')
          .eq('user_id', currentUser!.id)
          .maybeSingle();
      if (data == null) return {};
      return (data['card_ids'] as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  // ─── Direct Partner Invitations (1-Click) ──────────
  /// Subscribes to the current user's personal direct invitations channel.
  static RealtimeChannel? subscribeToUserInvites({
    required String userIdentifier,
    required Function(Map<String, dynamic> payload) onInviteReceived,
  }) {
    if (!isInitialized) return null;
    final sanitized = userIdentifier
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final channel = client.channel(
      'invites_$sanitized',
      opts: const RealtimeChannelConfig(self: true),
    );

    channel.onBroadcast(
      event: 'room_invite',
      callback: (payload) {
        onInviteReceived(payload);
      },
    );

    channel.subscribe();
    return channel;
  }

  /// Sends a direct 1-click room invitation to a linked partner.
  static Future<bool> sendPartnerInvite({
    required String targetPartnerIdentifier,
    required String roomId,
    required String roomCode,
    required String hostName,
  }) async {
    if (!isInitialized) return false;
    try {
      final sanitized = targetPartnerIdentifier
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final channel = client.channel('invites_$sanitized');
      channel.subscribe();
      await channel.sendBroadcastMessage(
        event: 'room_invite',
        payload: {
          'room_id': roomId,
          'room_code': roomCode,
          'host_name': hostName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
