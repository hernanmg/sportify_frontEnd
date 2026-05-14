import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/teams/sports_catalog_tab.dart';
import 'package:sportify_amateur/features/teams/categories_catalog_tab.dart';
import 'package:sportify_amateur/features/teams/teams_list_tab.dart';
import 'package:sportify_amateur/features/teams/team_form_screen.dart';

class TeamsManagementScreen extends StatefulWidget {
  const TeamsManagementScreen({super.key});

  @override
  State<TeamsManagementScreen> createState() => _TeamsManagementScreenState();
}

class _TeamsManagementScreenState extends State<TeamsManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _teamsListKey = GlobalKey<TeamsListTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openTeamForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TeamFormScreen()),
    );
    if (result != null) {
      await _teamsListKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.sports), text: 'Deportes'),
            Tab(icon: Icon(Icons.category), text: 'Categorías'),
            Tab(icon: Icon(Icons.groups), text: 'Equipos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const SportsCatalogTab(),
          const CategoriesCatalogTab(),
          TeamsListTab(key: _teamsListKey),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: _openTeamForm,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
