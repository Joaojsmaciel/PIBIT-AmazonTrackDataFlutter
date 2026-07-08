import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:amazon_track_data/core/errors/failures.dart';
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
  // Barco sendo editado (null = novo cadastro)
  BoatModel? _editingBoat;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    typeController = TextEditingController();
    capacityController = TextEditingController();
    cityController = TextEditingController();

    // Pré-popular se estiver editando
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final boat = ref.read(selectedBoatProvider);
      if (boat == null) return;
      _editingBoat = boat;
      nameController.text = boat.name;
      typeController.text = boat.type;
      capacityController.text = boat.capacity?.toString() ?? '';
      ref.read(_routeCitiesProvider.notifier).state =
          List<String>.from(boat.routeCities);
    });
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

  Future<void> _pickImageFromGallery() async {
    // Tenta permissões compatíveis (Android 13+ usa photos; versões antigas usam storage).
    final photosStatus = await Permission.photos.request();
    final storageStatus = await Permission.storage.request();

    final granted = photosStatus.isGranted || storageStatus.isGranted;
    if (!granted) {
      if (mounted) {
        context.showErrorSnackBar(
          'Permissão de fotos/armazenamento negada. '
          'Ative nas configurações do app.',
        );
      }
      return;
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (image != null) {
      ref.read(_pickedImageProvider.notifier).state = image;
    }
  }

  String _buildSaveErrorMessage(Object error) {
    if (error is StorageFailure) {
      final code = error.code ?? '';
      if (code == 'unauthorized') {
        return 'Falha no upload da imagem (sem autorização no Firebase Storage). '
            'Verifique as regras de segurança.';
      }
      if (code == 'object-not-found' || code == 'invalid-checksum') {
        return 'Falha no upload da imagem. Tente selecionar a foto novamente.';
      }
      return 'Erro no upload da imagem: ${error.message}';
    }
    if (error is FirestoreFailure) {
      return 'Erro ao salvar embarcação no banco: ${error.message}';
    }
    return 'Erro ao salvar embarcação: ${error.toString()}';
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

      UserModel? userData;
      try {
        userData = await authRepo.getCurrentUser();
      } catch (e) {
        userData = null;
      }

      final routeCities = ref.read(_routeCitiesProvider);
      final imageFile = pickedImage != null ? File(pickedImage.path) : null;
      final editing = _editingBoat;

      if (editing != null) {
        // ── Edição ──────────────────────────────────────────────────
        final updated = editing.copyWith(
          name: nameController.text.trim(),
          type: typeController.text.trim(),
          capacity: int.tryParse(capacityController.text) ?? 0,
          routeCities: routeCities,
          routes: selectedRoutes.isNotEmpty ? selectedRoutes : editing.routes,
        );
        await ref.read(updateBoatProvider(
          (boat: updated, imageFile: imageFile),
        ).future);
      } else {
        // ── Novo cadastro ────────────────────────────────────────────
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
        await ref.read(createBoatProvider(
          (boat: boat, imageFile: imageFile),
        ).future);
      }

      // Limpa o barco selecionado e os providers temporários
      ref.read(selectedBoatProvider.notifier).state = null;
      ref.read(_routeCitiesProvider.notifier).state = [];
      ref.read(_pickedImageProvider.notifier).state = null;

      if (mounted) {
        context.showSuccessSnackBar(editing != null
            ? 'Embarcação atualizada com sucesso!'
            : 'Embarcação cadastrada com sucesso!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go('/boat-list');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(_buildSaveErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickedImage = ref.watch(_pickedImageProvider);
    final routeCities = ref.watch(_routeCitiesProvider);
    final isEditing = _editingBoat != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Embarcação' : 'Registrar Embarcação'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(selectedBoatProvider.notifier).state = null;
            ref.read(_routeCitiesProvider.notifier).state = [];
            ref.read(_pickedImageProvider.notifier).state = null;
            context.go('/boat-list');
          },
        ),
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
                onPressed: _pickImageFromGallery,
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
                      : Text(isEditing ? 'Atualizar Embarcação' : 'Salvar Embarcação'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
