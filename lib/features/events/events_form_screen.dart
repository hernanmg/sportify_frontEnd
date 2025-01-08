import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/event_service.dart';
import 'package:sportify_amateur/models/event.dart';

class EventsFormScreen extends StatefulWidget {
  final String partidoId;

  EventsFormScreen({required this.partidoId});

  @override
  _EventsFormScreenScreenState createState() => _EventsFormScreenScreenState();
}

class _EventsFormScreenScreenState extends State<EventsFormScreen> {
  final EventService servicio = EventService();

  EventType _selectedType = EventType.training;
  DateTime _startTime = DateTime.now();
  int _duration = 60;
  String _location = '';
  String _fieldNumber = '';
  bool _isRequired = false;
  int _earlyArrival = 30;
  List<String> _selectedKit = [];
  bool _notifyPlayers = true;

  final List<String> _kitOptions = ['Jersey', 'Shorts', 'Socks'];

  Widget _buildEventTypeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: EventType.values.map((type) {
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedType == type
                            ? Colors.green
                            : Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getEventTypeIcon(type),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      type.toString().split('.').last,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter location',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            onChanged: (value) => _location = value,
          ),
        ],
      ),
    );
  }

  Widget _buildKitSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Kit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _kitOptions.map((kit) {
              final isSelected = _selectedKit.contains(kit);
              return FilterChip(
                selected: isSelected,
                label: Text(
                  kit,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
                selectedColor: Colors.green,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedKit.add(kit);
                    } else {
                      _selectedKit.remove(kit);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1C2E),
      appBar: AppBar(
        title: Text('Add Event'),
        backgroundColor: Color(0xFF2A2D3E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEventTypeSelector(),
            SizedBox(height: 16),
            _buildLocationField(),
            SizedBox(height: 16),
            _buildKitSelector(),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2A2D3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Notify Players',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _notifyPlayers,
                    onChanged: (value) =>
                        setState(() => _notifyPlayers = value),
                    activeColor: Colors.green,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Required Event',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _isRequired,
                    onChanged: (value) =>
                        setState(() => _isRequired = value),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Aquí iría la lógica para crear el evento
              },
              child: Text(
                'Create Event',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.training:
        return Icons.sports;
      case EventType.game:
        return Icons.sports_soccer;
      case EventType.strength:
        return Icons.fitness_center;
      case EventType.testing:
        return Icons.speed;
      case EventType.recover:
        return Icons.healing;
    }
  }
}
