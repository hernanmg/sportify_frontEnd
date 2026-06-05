import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_extras_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:flutter/services.dart';

class SponsorsScreen extends StatefulWidget {
  const SponsorsScreen({super.key});

  @override
  State<SponsorsScreen> createState() => _SponsorsScreenState();
}

class _SponsorsScreenState extends State<SponsorsScreen> {
  final _extras = TeamExtrasService();
  final _teamService = TeamService();
  final _picker = ImagePicker();

  List<MyTeamOption> _teams = [];
  int? _teamId;
  List<Map<String, dynamic>> _sponsors = [];
  bool _loading = true;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = await AuthStorageService().getRole();
    _isStaff = role == 'super_admin' ||
        role == 'manager' ||
        role == 'admin' ||
        role == 'team_captain' ||
        role == 'dt';
    try {
      final teams =
          MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _teamId = teams.isNotEmpty ? teams.first.teamId : null;
      });
      if (_teamId != null) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TeamExtrasService.errorMessage(e))),
        );
      }
    }
  }

  Future<void> _load() async {
    final teamId = _teamId;
    if (teamId == null) return;
    setState(() => _loading = true);
    try {
      final list = await _extras.getSponsors(teamId);
      if (!mounted) return;
      setState(() {
        _sponsors = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TeamExtrasService.errorMessage(e))),
      );
    }
  }

  Future<String?> _pickLogoDataUri() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 72,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final mime = picked.mimeType ?? 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Future<void> _openSponsorForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final nameController =
        TextEditingController(text: existing?['name']?.toString() ?? '');
    final descController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final socialController = TextEditingController(
      text: existing?['website']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: existing?['amountContributed']?.toString() ?? '',
    );
    String? logoPreview = existing?['logoUrl']?.toString();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEdit ? 'Editar patrocinador' : 'Nuevo patrocinador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final uri = await _pickLogoDataUri();
                    if (uri != null) setDialog(() => logoPreview = uri);
                  },
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepOrange.shade100,
                    backgroundImage: _logoImageProvider(logoPreview),
                    child: logoPreview == null || logoPreview!.isEmpty
                        ? const Icon(Icons.add_a_photo)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tocá el círculo para elegir logo',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej. Apoya la cuota social del plantel',
                  ),
                  maxLines: 2,
                ),
                TextField(
                  controller: socialController,
                  decoration: const InputDecoration(
                    labelText: 'Instagram o red social',
                    hintText: 'https://instagram.com/tu_cuenta',
                    helperText:
                        'Sitio web, Instagram, Facebook u otra red (URL completa)',
                  ),
                ),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Aporte (\$)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || _teamId == null) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      final payload = {
        'name': name,
        'description': descController.text.trim(),
        'website': socialController.text.trim(),
        'logoUrl': logoPreview,
        'amount': double.tryParse(amountController.text.trim()),
      };
      if (isEdit) {
        await _extras.updateSponsor(
          _teamId!,
          existing['id'] as int,
          name: payload['name'] as String,
          description: (payload['description'] as String).isEmpty
              ? ''
              : payload['description'] as String,
          website: (payload['website'] as String).isEmpty
              ? ''
              : payload['website'] as String,
          logoUrl: payload['logoUrl'] as String?,
          amountContributed: payload['amount'] as double?,
        );
      } else {
        await _extras.createSponsor(
          _teamId!,
          name: name,
          description: descController.text.trim(),
          website: socialController.text.trim(),
          logoUrl: logoPreview,
          amountContributed: double.tryParse(amountController.text.trim()),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TeamExtrasService.errorMessage(e))),
        );
      }
    }
  }

  Future<void> _deleteSponsor(Map<String, dynamic> sponsor) async {
    final teamId = _teamId;
    if (teamId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar patrocinador'),
        content: Text(
          '¿Eliminar "${sponsor['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _extras.removeSponsor(teamId, sponsor['id'] as int);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TeamExtrasService.errorMessage(e))),
        );
      }
    }
  }

  ImageProvider? _logoImageProvider(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    if (logoUrl.startsWith('data:image')) {
      try {
        final b64 = logoUrl.split(',').last;
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }
    if (logoUrl.startsWith('http')) {
      return NetworkImage(logoUrl);
    }
    return null;
  }

  void _copySocialLink(String? url) {
    if (url == null || url.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: url.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado al portapapeles')),
    );
  }

  String _socialLabel(String? url) {
    if (url == null || url.isEmpty) return '';
    final lower = url.toLowerCase();
    if (lower.contains('instagram')) return 'Instagram';
    if (lower.contains('facebook')) return 'Facebook';
    if (lower.contains('tiktok')) return 'TikTok';
    if (lower.contains('twitter') || lower.contains('x.com')) return 'X';
    return 'Web';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrocinadores'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _isStaff && _teamId != null
          ? FloatingActionButton(
              onPressed: () => _openSponsorForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: _teams.isEmpty
          ? const Center(child: Text('No tenés equipos asignados'))
          : Column(
              children: [
                if (_teams.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      value: _teamId,
                      decoration: const InputDecoration(
                        labelText: 'Equipo',
                        border: OutlineInputBorder(),
                      ),
                      items: _teams
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.teamId,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _teamId = v);
                        _load();
                      },
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _sponsors.isEmpty
                          ? const Center(
                              child: Text('Aún no hay patrocinadores'),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: _sponsors.length,
                                itemBuilder: (_, i) {
                                  final s = _sponsors[i];
                                  final name =
                                      s['name']?.toString() ?? 'Patrocinador';
                                  final social = s['website']?.toString();
                                  final amount = s['amountContributed'];
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: _isStaff
                                          ? () => _openSponsorForm(
                                                existing: s,
                                              )
                                          : null,
                                      onLongPress: _isStaff
                                          ? () => _deleteSponsor(s)
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 32,
                                              backgroundColor:
                                                  Colors.deepOrange.shade50,
                                              backgroundImage:
                                                  _logoImageProvider(
                                                s['logoUrl']?.toString(),
                                              ),
                                              child:
                                                  (s['logoUrl'] == null ||
                                                          (s['logoUrl']
                                                                  as String?)
                                                              ?.isEmpty ==
                                                          true)
                                                      ? Text(
                                                          name
                                                              .substring(0, 1)
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 22,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      : null,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (amount != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '\$$amount',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                            if (social != null &&
                                                social.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: () =>
                                                    _copySocialLink(social),
                                                child: Text(
                                                  _socialLabel(social),
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (_isStaff) ...[
                                              const Spacer(),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size: 20,
                                                    ),
                                                    tooltip: 'Editar',
                                                    onPressed: () =>
                                                        _openSponsorForm(
                                                      existing: s,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete_outline,
                                                      size: 20,
                                                      color: Colors.red.shade700,
                                                    ),
                                                    tooltip: 'Eliminar',
                                                    onPressed: () =>
                                                        _deleteSponsor(s),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}
