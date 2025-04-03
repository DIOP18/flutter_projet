import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProjectFilesTab extends StatefulWidget {
  final String projectId;

  const ProjectFilesTab({super.key, required this.projectId});

  @override
  _ProjectFilesTabState createState() => _ProjectFilesTabState();
}

class _ProjectFilesTabState extends State<ProjectFilesTab> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _getProjectDirectory() async {
    // Obtenir le répertoire de documents de l'application
    final appDocDir = await getApplicationDocumentsDirectory();

    // Créer un dossier spécifique pour les projets
    final projectDir = Directory('${appDocDir.path}/projects/${widget.projectId}');

    // Créer le dossier s'il n'existe pas
    if (!projectDir.existsSync()) {
      projectDir.createSync(recursive: true);
    }

    return projectDir;
  }

  Future<void> _loadFiles() async {
    final projectDir = await _getProjectDirectory();

    setState(() {
      // Lister tous les fichiers du dossier du projet
      files = projectDir.listSync();
    });
  }

  Future<void> _uploadFile() async {
    try {
      // Ouvrir le sélecteur de fichiers
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      // Obtenir le répertoire du projet
      final projectDir = await _getProjectDirectory();

      // Fichier sélectionné
      final pickedFile = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Créer le chemin de destination
      final destinationFile = File('${projectDir.path}/$fileName');

      // Copier le fichier
      await pickedFile.copy(destinationFile.path);

      // Actualiser la liste des fichiers
      _loadFiles();

      // Afficher un message de succès
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          elevation: 6,
          title: Text("Succès"),

          content: Text("Fichier $fileName ajouté avec succès !"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );

    } catch (e) {
      // Gérer les erreurs
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          elevation: 6,
          title: Text("Erreur"),
          content: Text("erreur lors de l'ajout du fichier : $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadFile(FileSystemEntity file) async {
    try {
      // Ouvrir le sélecteur de répertoire pour enregistrer
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) return;

      // Copier le fichier vers le répertoire sélectionné
      final fileName = path.basename(file.path);
      final destinationFile = File('$selectedDirectory/$fileName');

      await File(file.path).copy(destinationFile.path);

      showDialog(
        context: context,

        builder: (context) => AlertDialog(
          elevation: 6,
          title: Text("Téléchargement Réussi"),
          content: Text("Le fichier $fileName a été téléchargé avec succès."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );

    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          elevation: 6,
          title: Text("Erreur"),
          content: Text("Une erreur est survenue lors du téléchargement : $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 70),
              backgroundColor: const Color(0xFF2C3E50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _uploadFile,
            child: Text(
              "Ajouter un fichier",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 17
              ),
            ),
          ),
        ),
        Expanded(
          child: files.isEmpty
              ? const Center(child: Text("Aucun fichier disponible"))
              : ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                title: Text(path.basename(file.path)),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(file),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}