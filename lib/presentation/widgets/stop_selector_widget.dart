import 'package:flutter/material.dart';
import 'package:amazon_track_data/data/models/stop_model.dart';

class StopSelectorWidget extends StatefulWidget {
  final List<StopModel> stops;
  final Function(StopModel) onStopSelected;
  final StopModel? selectedStop;

  const StopSelectorWidget({
    Key? key,
    required this.stops,
    required this.onStopSelected,
    this.selectedStop,
  }) : super(key: key);

  @override
  State<StopSelectorWidget> createState() => _StopSelectorWidgetState();
}

class _StopSelectorWidgetState extends State<StopSelectorWidget> {
  late List<StopModel> filteredStops;

  @override
  void initState() {
    super.initState();
    filteredStops = widget.stops;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar parada...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            setState(() {
              filteredStops = widget.stops
                  .where((stop) =>
                      stop.name.toLowerCase().contains(value.toLowerCase()) ||
                      stop.city.toLowerCase().contains(value.toLowerCase()))
                  .toList();
            });
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: filteredStops.length,
            itemBuilder: (context, index) {
              final stop = filteredStops[index];
              return ListTile(
                title: Text(stop.name),
                subtitle: Text('${stop.city}, ${stop.state}'),
                trailing: Radio<StopModel>(
                  value: stop,
                  groupValue: widget.selectedStop,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onStopSelected(value);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
