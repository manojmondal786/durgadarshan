import 'package:flutter/material.dart';

import '../models/pandal.dart';
import '../models/visit.dart';
import '../state/visits_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'star_rating.dart';

/// What the user did in a [VisitSheet].
enum VisitSheetOutcome { saved, removed }

/// Marks a pandal as visited, or edits that visit: when (now by default, or
/// earlier), an optional star rating and an optional note.
class VisitSheet extends StatefulWidget {
  const VisitSheet({super.key, required this.pandal, required this.visits});

  final Pandal pandal;
  final VisitsController visits;

  /// Shows the sheet; resolves to what was done, or null if dismissed.
  static Future<VisitSheetOutcome?> show(
    BuildContext context, {
    required Pandal pandal,
    required VisitsController visits,
  }) {
    return showModalBottomSheet<VisitSheetOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => VisitSheet(pandal: pandal, visits: visits),
    );
  }

  @override
  State<VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends State<VisitSheet> {
  late final Visit? _existing = widget.visits.visitOf(widget.pandal.id);
  late DateTime _visitedAt = _existing?.visitedAt ?? _nowToTheMinute();
  late int? _rating = _existing?.rating;
  late final _note = TextEditingController(text: _existing?.note);

  static DateTime _nowToTheMinute() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  bool get _inFuture => _visitedAt.isAfter(DateTime.now());

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitedAt.isAfter(now) ? now : _visitedAt,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: 'Date of your visit',
    );
    if (picked == null || !mounted) return;
    setState(
      () => _visitedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _visitedAt.hour,
        _visitedAt.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_visitedAt),
      helpText: 'Time of your visit',
    );
    if (picked == null || !mounted) return;
    setState(
      () => _visitedAt = DateTime(
        _visitedAt.year,
        _visitedAt.month,
        _visitedAt.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  void _save() {
    final note = _note.text.trim();
    widget.visits.save(
      Visit(
        pandalId: widget.pandal.id,
        visitedAt: _visitedAt,
        rating: _rating,
        note: note.isEmpty ? null : note,
      ),
    );
    Navigator.of(context).pop(VisitSheetOutcome.saved);
  }

  void _remove() {
    widget.visits.remove(widget.pandal.id);
    Navigator.of(context).pop(VisitSheetOutcome.removed);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final editing = _existing != null;
    final inFuture = _inFuture;

    return Padding(
      // Keeps the note field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing ? 'Edit your visit' : 'Mark as visited',
                style: AppTypography.serif(fontSize: 22, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                widget.pandal.name,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 18),
              const _Label('When'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(formatVisitDate(_visitedAt)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(formatVisitTime(_visitedAt)),
                  ),
                ],
              ),
              if (inFuture) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'That time hasn’t come yet. Choose when you visited.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.vermilion,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const _Label('Your rating (optional)'),
              StarRating(
                rating: _rating,
                size: 30,
                onChanged: (rating) => setState(() => _rating = rating),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: Visit.maxNoteLength,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'What stood out? The idol, the theme, the bhog…',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (editing)
                    TextButton.icon(
                      onPressed: _remove,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.vermilion,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove visit'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: inFuture ? null : _save,
                    child: Text(editing ? 'Save' : 'Mark visited'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: AppColors.maroon),
    );
  }
}
