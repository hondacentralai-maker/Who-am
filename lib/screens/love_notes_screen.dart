import 'package:flutter/material.dart';
import '../models/love_note.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/interactive_3d_card.dart';

class LoveNotesScreen extends StatefulWidget {
  const LoveNotesScreen({super.key});

  @override
  State<LoveNotesScreen> createState() => _LoveNotesScreenState();
}

class _LoveNotesScreenState extends State<LoveNotesScreen> {
  List<LoveNote> _notes = [];
  String _filter = 'all'; // 'all', 'capsules', 'opened'

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notes = PreferencesService.getLoveNotes();
    });
  }

  List<LoveNote> get _filteredNotes {
    if (_filter == 'capsules') {
      return _notes.where((n) => n.isLocked).toList();
    } else if (_filter == 'opened') {
      return _notes.where((n) => !n.isLocked).toList();
    }
    return _notes;
  }

  void _showAddNoteDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final profile = PreferencesService.getCouplesProfile();
    String selectedAuthor = profile.partner1Name;
    String selectedEmoji = '💌';
    bool isCapsule = false;
    DateTime unlockDate = DateTime.now().add(const Duration(days: 7));

    final emojis = ['💌', '🎁', '💖', '💍', '🌟', '🕊️', '🌹'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'كتابة رسالة أو كبسولة زمنية 💌',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),

                // Author Choice
                Row(
                  children: [
                    const Text('من الكاتب؟: ', style: TextStyle(fontWeight: FontWeight.w700)),
                    ChoiceChip(
                      label: Text(profile.partner1Name),
                      selected: selectedAuthor == profile.partner1Name,
                      onSelected: (v) {
                        if (v) setModalState(() => selectedAuthor = profile.partner1Name);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(profile.partner2Name),
                      selected: selectedAuthor == profile.partner2Name,
                      onSelected: (v) {
                        if (v) setModalState(() => selectedAuthor = profile.partner2Name);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الرسالة',
                    hintText: 'مثال: سر صغير لك، كلمة من قلبي...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'نص الرسالة أو الذكرى',
                    hintText: 'اكتب مشاعرك بحرية وصدق...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Emoji Picker
                Row(
                  children: emojis.map((e) {
                    final isSel = e == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedEmoji = e),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.palePurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSel
                              ? Border.all(color: AppColors.purple, width: 2)
                              : null,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Capsule Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('قفل كـ كبسولة زمنية مؤجلة 🎁'),
                  subtitle: Text(
                    isCapsule
                        ? 'تُفتح بتاريخ: ${unlockDate.year}/${unlockDate.month}/${unlockDate.day}'
                        : 'تظهر وتُقرأ فوراً',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isCapsule,
                  onChanged: (val) async {
                    if (val) {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: unlockDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        locale: const Locale('ar', ''),
                      );
                      if (picked != null) {
                        setModalState(() {
                          isCapsule = true;
                          unlockDate = picked;
                        });
                      }
                    } else {
                      setModalState(() => isCapsule = false);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Submit Button
                FilledButton.icon(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final content = contentCtrl.text.trim();
                    if (title.isNotEmpty && content.isNotEmpty) {
                      final newNote = LoveNote(
                        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
                        authorName: selectedAuthor,
                        title: title,
                        content: content,
                        createdAt: DateTime.now(),
                        unlockDate: isCapsule ? unlockDate : null,
                        emoji: selectedEmoji,
                      );
                      await PreferencesService.addLoveNote(newNote);
                      await PreferencesService.addPoints(15);
                      await PreferencesService.unlockAchievement('love_capsule');
                      GameAudioService().playSuccess();
                      PreferencesService.triggerHaptic(AppHapticType.heavy);
                      _loadNotes();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        CelebrationOverlay.show(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('حفظ في صندوق الحب 💌'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNote(LoveNote note) {
    if (note.isLocked) {
      GameAudioService().playBuzzer();
      PreferencesService.triggerHaptic(AppHapticType.medium);
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.accentGold),
              SizedBox(width: 8),
              Text('كبسولة زمنية مغلقة 🎁'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'هذه الرسالة كبسولة زمنية مؤجلة لا يمكن فتحها حتى يحين تاريخها السعيد!',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.palePurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'متبقي ${note.daysUntilUnlock} يوماً للفتح 🎉',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepPurple,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسنًا، سأنتظر بشوق! ❤️'),
            ),
          ],
        ),
      );
      return;
    }

    PreferencesService.markLoveNoteOpened(note.id);
    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playWin();
    if (mounted) {
      CelebrationOverlay.show(context);
    }
    _loadNotes();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(note.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'من: ${note.authorName}',
                        style: const TextStyle(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.palePurple.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                note.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'حذف الرسالة',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () async {
                    await PreferencesService.deleteLoveNote(note.id);
                    _loadNotes();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق ❤️'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('كبسولة رسائل الحب 💌'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('رسالة جديدة', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل 💌'),
                    selected: _filter == 'all',
                    onSelected: (v) {
                      if (v) setState(() => _filter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('الكبسولات المؤجلة 🎁'),
                    selected: _filter == 'capsules',
                    onSelected: (v) {
                      if (v) setState(() => _filter = 'capsules');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('المفتوحة ✨'),
                    selected: _filter == 'opened',
                    onSelected: (v) {
                      if (v) setState(() => _filter = 'opened');
                    },
                  ),
                ],
              ),
            ),

            // Notes List
            Expanded(
              child: notes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📬', style: TextStyle(fontSize: 60)),
                          SizedBox(height: 12),
                          Text(
                            'لا توجد رسائل في هذا القسم بعد',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'اكتبا لبعضكما رسائل حب أو كبسولات تفتح لاحقاً',
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notes.length,
                      itemBuilder: (context, idx) {
                        final note = notes[idx];
                        final isLocked = note.isLocked;

                        return Interactive3DCard(
                          borderRadius: BorderRadius.circular(20),
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () => _openNote(note),
                          child: Container(
                            decoration: AppDecorations.outlinedCard(),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? AppColors.accentGold.withValues(alpha: 0.18)
                                      : AppColors.palePurple,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    isLocked ? '🎁' : note.emoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              ),
                              title: Text(
                                isLocked ? 'كبسولة زمنية مشوقة...' : note.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.ink,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  isLocked
                                      ? 'مغلقة • متبقي ${note.daysUntilUnlock} يوماً للفتح'
                                      : 'من: ${note.authorName} • انقر للقراءة',
                                  style: TextStyle(
                                    color: isLocked ? AppColors.accentGold : AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: isLocked ? FontWeight.w700 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              trailing: Icon(
                                isLocked ? Icons.lock_rounded : Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: isLocked ? AppColors.accentGold : AppColors.muted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
