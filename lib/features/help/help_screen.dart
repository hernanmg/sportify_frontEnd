import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/help/help_article.dart';
import 'package:sportify_amateur/features/help/help_content.dart';
import 'package:sportify_amateur/features/help/help_navigation.dart';
import 'package:sportify_amateur/features/help/help_previews.dart';

class HelpScreen extends StatefulWidget {
  final String? initialQuery;
  final String? highlightArticleId;

  const HelpScreen({
    super.key,
    this.initialQuery,
    this.highlightArticleId,
  });

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  final Map<String, GlobalKey> _articleKeys = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _query = widget.initialQuery?.trim() ?? '';
    for (final article in HelpContent.articles) {
      _articleKeys[article.id] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighlight();
    });
  }

  void _scrollToHighlight() {
    final id = widget.highlightArticleId;
    if (id == null) return;
    final key = _articleKeys[id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final results = HelpContent.search(_query);
    final grouped = <String, List<HelpArticle>>{};
    for (final article in results) {
      final cat = HelpContent.categoryFor(article);
      grouped.putIfAbsent(cat, () => []).add(article);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de ayuda'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar: convocatoria, alineación, cuotas…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
              ],
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchChanged,
            ),
          ),
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${results.length} resultado${results.length == 1 ? '' : 's'} para «$_query»',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? _EmptyHelpState(query: _query, onClear: _clearSearch)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_query.isEmpty) ...[
                        _WelcomeBanner(
                          onTopicTap: (topic) {
                            _searchController.text = topic;
                            _onSearchChanged(topic);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final category in HelpContent.categories)
                        if (grouped.containsKey(category)) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Text(
                              category,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...grouped[category]!.map(
                            (article) => _HelpArticleCard(
                              key: _articleKeys[article.id],
                              article: article,
                              expandedByDefault: _query.isNotEmpty ||
                                  article.id == widget.highlightArticleId,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final ValueChanged<String> onTopicTap;

  const _WelcomeBanner({required this.onTopicTap});

  @override
  Widget build(BuildContext context) {
    const topics = [
      ('Convocatorias', 'convocatoria'),
      ('Alineación', 'alineación'),
      ('Finanzas', 'cuotas'),
      ('Calendario', 'calendario'),
    ];

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(
            alpha: 0.45,
          ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¿En qué te ayudamos?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Explorá por tema o buscá una palabra. Cada guía explica paso a paso qué hacer.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics
                  .map(
                    (t) => ActionChip(
                      label: Text(t.$1),
                      onPressed: () => onTopicTap(t.$2),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHelpState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _EmptyHelpState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              'No encontramos guías para «$query»',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Probá con otra palabra: plantel, partido, perfil, notificaciones…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('Ver todas las guías'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpArticleCard extends StatefulWidget {
  final HelpArticle article;
  final bool expandedByDefault;

  const _HelpArticleCard({
    super.key,
    required this.article,
    this.expandedByDefault = false,
  });

  @override
  State<_HelpArticleCard> createState() => _HelpArticleCardState();
}

class _HelpArticleCardState extends State<_HelpArticleCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expandedByDefault;
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: article.color.withValues(alpha: 0.15),
              child: Icon(article.icon, color: article.color, size: 22),
            ),
            title: Text(
              article.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(article.summary),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...article.steps.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor:
                                    article.color.withValues(alpha: 0.2),
                                child: Text(
                                  '${e.key + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: article.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(e.value)),
                            ],
                          ),
                        ),
                      ),
                  if (article.previewType == 'lineup') ...[
                    const SizedBox(height: 12),
                    const LineupHelpPreview(),
                  ],
                  if (HelpNavigation.forArticle(article.id) != null) ...[
                    const SizedBox(height: 4),
                    FilledButton.tonalIcon(
                      onPressed: () => HelpNavigation.go(
                        context,
                        HelpNavigation.forArticle(article.id)!,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(HelpNavigation.forArticle(article.id)!.label),
                    ),
                  ],
                  if (article.tip != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates_outlined,
                              size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              article.tip!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
