/// Panel de Cursos (M6.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'course_progress_controller.dart';
import 'courses_data.dart';

class CoursesPanel extends ConsumerStatefulWidget {
  const CoursesPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<CoursesPanel> createState() => _CoursesPanelState();
}

class _CoursesPanelState extends ConsumerState<CoursesPanel> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  String? get _courseId {
    final reference = widget.tab.reference;
    return reference == null || reference.isEmpty ? null : reference;
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  @override
  void didUpdateWidget(covariant CoursesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.reference != oldWidget.tab.reference) {
      _query = '';
      _search.clear();
    }
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (_query == _search.text) return;
    setState(() => _query = _search.text);
  }

  void _openCourse(CourseDef course) {
    ref
        .read(workspaceProvider.notifier)
        .updateTab(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          reference: course.id,
        );
  }

  void _back() {
    ref
        .read(workspaceProvider.notifier)
        .updateTab(tileId: widget.tile.id, tabId: widget.tab.id, reference: '');
  }

  void _openLesson(CourseLesson lesson) {
    ref
        .read(workspaceProvider.notifier)
        .openTab(
          TabSpec(
            kind: PanelKind.bible,
            reference: lesson.reference,
            resourceId: kDefaultBibleResourceId,
          ),
        );
  }

  void _toggleLesson(CourseDef course, CourseLesson lesson) {
    ref.read(courseProgressProvider.notifier).toggle(course.id, lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final courses = courseDefinitions(l10n);
    final course = _courseId == null
        ? null
        : courses.where((c) => c.id == _courseId).firstOrNull;
    return Container(
      color: kPanelBg,
      child: course == null
          ? _buildHub(courses, l10n)
          : _buildCourse(course, l10n),
    );
  }

  Widget _buildHub(List<CourseDef> courses, AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final course in courses)
        if (query.isEmpty ||
            course.title.toLowerCase().contains(query) ||
            course.description.toLowerCase().contains(query))
          course,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, size: 18, color: kAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.panelTitleCourses,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            l10n.coursesIntro,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: kTextSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            key: const ValueKey('courses-search'),
            controller: _search,
            decoration: InputDecoration(
              hintText: l10n.coursesSearchHint,
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 17),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    l10n.coursesNoResults,
                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final course = visible[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kPanelBg,
                        border: Border.all(color: kCardBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        key: ValueKey('course-card-${course.id}'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openCourse(course),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Row(
                            children: [
                              Icon(course.icon, size: 22, color: kAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      course.description,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.coursesLessons(
                                        course.lessons.length,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: kAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: kTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCourse(CourseDef course, AppLocalizations l10n) {
    final progress = ref.watch(courseProgressProvider);
    final completed = course.lessons
        .where((lesson) => progress[course.id]?.contains(lesson.id) ?? false)
        .length;
    final total = course.lessons.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 14, 4),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('course-back'),
                iconSize: 18,
                tooltip: l10n.readerBack,
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            course.description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: kTextSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              key: const ValueKey('course-progress'),
              value: total == 0 ? 0 : completed / total,
              minHeight: 6,
              backgroundColor: kBorder,
              valueColor: const AlwaysStoppedAnimation(kAccent),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            completed == total
                ? l10n.courseCompleted
                : l10n.courseProgress(completed, total),
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            itemCount: total,
            itemBuilder: (context, index) {
              final lesson = course.lessons[index];
              final key = '${course.id}/${lesson.id}';
              final done = progress[course.id]?.contains(lesson.id) ?? false;
              return Container(
                key: ValueKey('course-lesson-$key'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  color: done ? kFieldFill : kPanelBg,
                  border: Border.all(color: kCardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      key: ValueKey('course-lesson-done-$key'),
                      value: done,
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => _toggleLesson(course, lesson),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${lesson.title}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lesson.detail,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: ValueKey('course-lesson-read-$key'),
                      onPressed: () => _openLesson(lesson),
                      child: Text(
                        l10n.courseLessonRead,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
