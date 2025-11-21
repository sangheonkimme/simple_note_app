import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/note_list_tile.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Note> _getNotesForDay(List<Note> allNotes, DateTime day) {
    return allNotes.where((note) {
      return isSameDay(note.createdAt, day) || isSameDay(note.updatedAt, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // We need a stream of all notes to populate the calendar.
    // Currently we have foldersStream, but maybe not all notes stream.
    // Let's check providers. If not available, we might need to add one or use a workaround.
    // For now, I'll assume we can get all notes or I'll add a provider.
    // Let's check `noteRepositoryProvider` or similar.
    // Actually `notesInFolderProvider` exists.
    // I'll create a `allNotesProvider` in `providers.dart` if it doesn't exist, 
    // or just use a FutureBuilder with `noteRepository.getAllNotes()` if available.
    // Checking `NoteRepository` next. For now, I will assume `allNotesStreamProvider` exists or I will add it.
    
    // Let's use a hypothetical `allNotesStreamProvider` and I will add it to `providers.dart` next.
    final allNotesAsync = ref.watch(allNotesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: allNotesAsync.when(
        data: (allNotes) {
          final selectedNotes = _getNotesForDay(allNotes, _selectedDay!);

          return Column(
            children: [
              TableCalendar<Note>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  return _getNotesForDay(allNotes, day);
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedNotes.length,
                  itemBuilder: (context, index) {
                    final note = selectedNotes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NoteListTile(note: note),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
