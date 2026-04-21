import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:amazon_track_data/data/models/boat_model.dart';
import 'package:amazon_track_data/data/models/user_model.dart';
import 'package:amazon_track_data/core/extensions/context_extensions.dart';
import 'package:amazon_track_data/presentation/providers/boat_provider.dart';
import 'package:amazon_track_data/presentation/providers/service_provider.dart';

final _pickedImageProvider = StateProvider<XFile?>((ref) => null);
final _selectedRoutesProvider = StateProvider<List<String>>((ref) => []);
final _routeCitiesProvider = StateProvider<List<String>>((ref) => []);

class BoatRegistrationScreen extends ConsumerStatefulWidget {
  const BoatRegistrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BoatRegistrationScreen> createState() =>
      _BoatRegistrationScreenState();
}

class _BoatRegistrationScreenState
    extends ConsumerState<BoatRegistrationScreen> {
  late final TextEditingController nameController;
  late final TextEditingController typeController;
  late final TextEditingController capacityController;
  late final TextEditingController cityController;
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    typeController = TextEditingController();
    capacityController = TextEditingController();
    cityController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    capacityController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void _addCity(List<String> current) {
    final city = cityController.text.trim();
    if (city.isEmpty || current.contains(city)) return;
    ref.read(_routeCitiesProvider.notifier).state = [...current, city];
    cityController.clear();
  }

  Future<void> _handleSaveBoat() async {
    if (!formKey.currentState!.validate()) return;

    final pickedImage = ref.read(_pickedImageProvider);
    final selectedRoutes = ref.read(_selectedRoutesProvider);
    
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userId = authRepo.getCurrentUserId();
      
      if (userId == null) {
        if (mounted) {
          context.showErrorSnackBar('Erro: usuário não autenticado');
        }
        return;
      }

      // Tentar buscar dados do usuário do Firestore
      UserModel? userData;
      try {
        userData = await authRepo.getCurrentUser();
      } catch (e) {
        // Se não conseguir buscar, usar dados mínimos
        userData = null;
      }

      final routeCities = ref.read(_routeCitiesProvider);

      final boat = BoatModel(
        id: const Uuid().v4(),
        ownerId: userId,
        ownerName: userData?.fullName ?? 'Barqueiro',
        name: nameController.text.trim(),
        routes: selectedRoutes,
        routeCities: routeCities,
        capacity: int.tryParse(capacityController.text) ?? 0,
        type: typeController.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final imageFile =
          pickedImage != null ? File(pickedImage.path) : null;

      await ref.read(createBoatProvider(
        (boat: boat, imageFile: imageFile),
      ).future);

      if (mounted) {
        context.showSuccessSnackBar('Embarcação cadastrada com sucesso!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go('/boat-list');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Erro ao salvar: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickedImage = ref.watch(_pickedImageProvider);
    final routeCities = ref.watch(_routeCitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Embarcação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // Foto
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: pickedImage != null
                    ? Image.file(
                        File(pickedImage.path),
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.directions_boat,
                        size: 60,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final image =
                      await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    ref.read(_pickedImageProvider.notifier).state =
                        image;
                  }
                },
                icon: const Icon(Icons.photo),
                label: const Text('Selecionar Foto'),
              ),
              const SizedBox(height: 24),

              // Nome
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Nome da Embarcação',
                  prefixIcon: Icon(Icons.directions_boat),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(
                  hintText: 'Tipo (ex: Barco, Lancha, Canoa)',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tipo é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Capacidade
              TextFormField(
                controller: capacityController,
                decoration: const InputDecoration(
                  hintText: 'Capacidade de Passageiros',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Capacidade é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Cidades da Rota
              const Text(
                'Cidades / Pontos da Rota',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Informe as cidades por onde a embarcação passa.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Manaus',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addCity(routeCities),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _addCity(routeCities),
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (routeCities.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: routeCities
                      .map(
                        (city) => Chip(
                          label: Text(city),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            ref
                                .read(_routeCitiesProvider.notifier)
                                .state = routeCities
                                .where((c) => c != city)
                                .toList();
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 24),

              // Botão de Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveBoat,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Salvar Embarcação'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
